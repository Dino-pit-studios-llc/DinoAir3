"""AI routes for chat endpoints.

Exposes POST /AI/chat and helper utilities to build payloads and parse
responses from the core router services.
"""

from __future__ import annotations

import json
import logging
from collections.abc import Iterable, Mapping, Sequence
from typing import Any, cast

from fastapi import APIRouter, HTTPException
from starlette import status

from core_router.errors import AdapterError, NoHealthyService, ServiceNotFound
from core_router.errors import ValidationError as CoreValidationError

from ..schemas import ChatRequest, ChatResponse
from ..services import router_client
from ..services.tool_schema_generator import get_tool_registry

logger = logging.getLogger(__name__)

# ErrorResponse model may not exist in local test stubs; provide a safe pydantic fallback
try:
    from core_router.errors import ErrorResponse as ErrorResponseModel  # type: ignore[import-not-found,unused-ignore]
except ImportError:  # pragma: no cover
    from pydantic import BaseModel

    class ErrorResponseModel(BaseModel):  # type: ignore[misc,unused-ignore]
        """Minimal error response model for FastAPI responses when core_router is unavailable."""

        detail: str | None = None
        code: str | None = None
        message: str | None = None
        error: str | None = None


router = APIRouter()


def _get_tool_schemas_from_params(extra_params: Mapping | None) -> list[dict[str, Any]]:
    """Helper to retrieve tool schemas based on extra_params."""
    enable_tools = _extract_bool_param(extra_params, "enable_tools", False)
    if not enable_tools:
        return []
    try:
        registry = get_tool_registry()
        requested_tools = _extract_list_param(extra_params, "tools")
        tool_schemas = registry.get_tool_schemas(requested_tools)
        logger.info("Function calling enabled with %d tools", len(tool_schemas))
        return tool_schemas
    except Exception as e:
        logger.warning("Failed to load tools for function calling, continuing without tools: %s", e)
        return []


@router.post(
    "/ai/chat",
    tags=["ai"],
    response_model=ChatResponse,
    status_code=status.HTTP_200_OK,
    responses={
        status.HTTP_422_UNPROCESSABLE_ENTITY: {
            "model": ErrorResponseModel,
            "description": "Validation error",
        },
        status.HTTP_401_UNAUTHORIZED: {
            "model": ErrorResponseModel,
            "description": "Unauthorized",
        },
        status.HTTP_413_REQUEST_ENTITY_TOO_LARGE: {
            "model": ErrorResponseModel,
            "description": "Request too large",
        },
        status.HTTP_415_UNSUPPORTED_MEDIA_TYPE: {
            "model": ErrorResponseModel,
            "description": "Unsupported media type",
        },
        status.HTTP_500_INTERNAL_SERVER_ERROR: {
            "model": ErrorResponseModel,
            "description": "Internal server error",
        },
        status.HTTP_502_BAD_GATEWAY: {
            "model": ErrorResponseModel,
            "description": "Bad gateway",
        },
        status.HTTP_503_SERVICE_UNAVAILABLE: {
            "model": ErrorResponseModel,
            "description": "Service unavailable",
        },
        status.HTTP_504_GATEWAY_TIMEOUT: {
            "model": ErrorResponseModel,
            "description": "Gateway timeout",
        },
    },
)
async def ai_chat(req: ChatRequest) -> ChatResponse:
    """
    POST /ai/chat
    - Router-first chat endpoint for any client integration.
    - Accepts OpenAI-style 'messages' and routes via the ServiceRouter
      for uniform health, metrics, and policy-based selection.
    - Supports OpenAI function calling when enabled via extra_params.
    - Selection:
        * Uses extra_params.router_service (exact serviceName), or
        * extra_params.router_tag (+ optional extra_params.router_policy), or
        * defaults to tag 'chat'.
    - Generation knobs: extra_params may include temperature/top_p/max_tokens,
      which are mapped to LM Studio's 'options' payload.
    - Function calling: Set extra_params.enable_tools=true to enable function calling.
    """
    (
        mapping_params,
        messages,
        options,
        tool_schemas,
        payload,
    ) = _prepare_initial_invocation(req)

    svc_name, tag, policy = _parse_routing_params(mapping_params)

    router_instance = router_client.get_router()
    result_dict = _execute_chat_round(router_instance, svc_name, tag, policy, payload)

    result_dict, function_call_results = await _maybe_continue_with_function_calls(
        mapping_params,
        result_dict,
        router_instance,
        svc_name,
        tag,
        policy,
        messages,
        options,
        tool_schemas,
    )

    return _build_chat_response(result_dict, function_call_results)


def _prepare_initial_invocation(
    req: ChatRequest,
) -> tuple[
    dict[str, Any] | None,
    list[dict[str, str]],
    dict[str, Any],
    list[dict[str, Any]],
    dict[str, Any],
]:
    mapping_params = _normalize_extra_params(req.extra_params)
    messages = _build_chat_messages(req.messages)
    options = _extract_options(mapping_params)
    tool_schemas = _get_tool_schemas_from_params(mapping_params)
    payload = _build_payload(messages, options, tool_schemas)
    return mapping_params, messages, options, tool_schemas, payload


def _normalize_extra_params(extra_params: Any) -> dict[str, Any] | None:
    return dict(extra_params) if isinstance(extra_params, Mapping) else None


def _build_chat_messages(messages: Sequence[Any]) -> list[dict[str, str]]:
    return [{"role": m.role.value, "content": m.content} for m in messages]


def _execute_chat_round(
    router_instance: Any,
    svc_name: str | None,
    tag: str | None,
    policy: str | None,
    payload: Mapping[str, Any],
) -> dict[str, Any] | None:
    result_obj = _execute_router_call(router_instance, svc_name, tag, policy, payload)
    return _ensure_dict(result_obj)


def _ensure_dict(value: Any) -> dict[str, Any] | None:
    return cast(dict[str, Any], value) if isinstance(value, dict) else None


async def _maybe_continue_with_function_calls(
    mapping_params: dict[str, Any] | None,
    result_dict: dict[str, Any] | None,
    router_instance: Any,
    svc_name: str | None,
    tag: str | None,
    policy: str | None,
    base_messages: list[dict[str, str]],
    options: Mapping[str, Any] | None,
    tool_schemas: list[dict[str, Any]] | None,
) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
    if (
        not mapping_params
        or not mapping_params.get("enable_tools")
        or not result_dict
        or not _has_function_calls(result_dict)
    ):
        return result_dict, []

    function_call_results = await _handle_function_calls(result_dict)

    if function_call_results and _should_continue_conversation(mapping_params):
        updated_messages = base_messages + _build_function_call_messages(result_dict, function_call_results)
        updated_payload = _build_payload(updated_messages, options, tool_schemas)
        result_dict = _execute_chat_round(router_instance, svc_name, tag, policy, updated_payload)

    return result_dict, function_call_results


def _build_chat_response(
    result_dict: dict[str, Any] | None,
    function_call_results: list[dict[str, Any]],
) -> ChatResponse:
    text = _extract_first_message_text(result_dict)
    model: str | None = None
    finish_reason: str | None = None
    usage: dict[str, int] | None = None

    if result_dict is not None:
        mv = result_dict.get("model")
        model = mv if isinstance(mv, str) else None
        finish_reason = _safe_first_finish_reason(result_dict)
        usage = _extract_usage(result_dict)

    metadata: dict[str, Any] = {}
    if function_call_results:
        metadata["function_calls"] = function_call_results

    return ChatResponse(
        success=bool(text) or bool(function_call_results),
        content=text,
        finish_reason=finish_reason,
        model=model,
        usage=usage,
        metadata=metadata,
    )


def _extract_options(extra_params: Mapping[str, Any] | None) -> dict[str, Any]:
    out: dict[str, Any] = {}
    if isinstance(extra_params, Mapping):
        for k in (
            "temperature",
            "top_p",
            "max_tokens",
            "presence_penalty",
            "frequency_penalty",
        ):
            v = extra_params.get(k)
            if v is not None:
                out[k] = v
    return out


def _build_payload(
    messages: list[dict[str, str]],
    options: Mapping[str, Any] | None,
    tool_schemas: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {"messages": messages}
    if options:
        payload["options"] = dict(options)
    if tool_schemas:
        payload["tools"] = tool_schemas
    return payload


def _safe_str(obj: Any) -> str | None:
    try:
        s = str(obj)
        return s or None
    except Exception:
        return None


def _pick_first_str(m: Mapping[str, Any], *keys: str) -> str | None:
    for k in keys:
        v = m.get(k)
        if isinstance(v, str) and v:
            return v
    return None


def _normalize_tag(value: Any) -> str | None:
    if isinstance(value, str):
        return value or None
    if isinstance(value, list):
        for item in value:
            if isinstance(item, str) and item:
                return item
            if s := _safe_str(item):
                return s
    return None


def _parse_routing_params(
    extra_params: Mapping[str, Any] | None,
) -> tuple[str | None, str | None, str | None]:
    if not isinstance(extra_params, Mapping):
        return None, None, None

    svc_name = _pick_first_str(extra_params, "router_service", "serviceName")
    tag = _normalize_tag(extra_params.get("router_tag") or extra_params.get("router_tags"))
    policy = _pick_first_str(extra_params, "router_policy")

    return svc_name, tag, policy


def _execute_router_call(
    r: Any,
    svc_name: str | None,
    tag: str | None,
    policy: str | None,
    payload: Mapping[str, Any],
) -> Any:
    try:
        return _call_router(r, svc_name, tag, policy, payload)
    except (ServiceNotFound, NoHealthyService) as exc:
        return _handle_router_service_error(r, payload, exc)
    except CoreValidationError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except AdapterError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc


def _call_router(
    router_instance: Any,
    svc_name: str | None,
    tag: str | None,
    policy: str | None,
    payload: Mapping[str, Any],
) -> Any:
    if isinstance(svc_name, str) and svc_name.strip():
        return router_instance.execute(svc_name.strip(), payload)
    return router_instance.execute_by(
        _normalize_router_tag(tag),
        payload,
        _normalize_router_policy(policy),
    )


def _handle_router_service_error(
    router_instance: Any,
    payload: Mapping[str, Any],
    exc: Exception,
) -> Any:
    try:
        logger.info("Primary service failed (%s), trying mock fallback...", exc)
        return router_instance.execute_by("mock", payload, "first_healthy")
    except (ServiceNotFound, NoHealthyService):
        raise _translate_router_exception(exc) from exc


def _translate_router_exception(exc: Exception) -> HTTPException:
    if isinstance(exc, ServiceNotFound):
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail=str(exc),
    )


def _normalize_router_tag(tag: str | None) -> str:
    return (tag or "chat").strip().lower()


def _normalize_router_policy(policy: str | None) -> str:
    return (policy or "first_healthy").strip().lower()


def _choice_content(choices: Any) -> str:
    """Return first non-empty content/text found in choices list."""
    if not isinstance(choices, list):
        return ""
    for raw in choices:
        if not isinstance(raw, Mapping):
            continue
        msg = raw.get("message")
        if isinstance(msg, Mapping):
            content = msg.get("content")
            if isinstance(content, str) and content:
                return content
        txt = raw.get("text")
        if isinstance(txt, str) and txt:
            return txt
    return ""


def _extract_first_message_text(data: Mapping[str, Any] | None) -> str:
    if not isinstance(data, Mapping):
        return ""
    try:
        if from_choices := _choice_content(data.get("choices")):
            return from_choices
        val = data.get("content")
        return val if isinstance(val, str) else ""
    except Exception:
        return ""


def _safe_first_finish_reason(data: Mapping[str, Any] | None) -> str | None:
    try:
        if not isinstance(data, Mapping):
            return None
        choices_val = data.get("choices")
        if isinstance(choices_val, list):
            items_any: list[Any] = cast("list[Any]", choices_val)
            for raw in items_any:
                if isinstance(raw, Mapping):
                    item: Mapping[str, Any] = cast("Mapping[str, Any]", raw)
                    fr = item.get("finish_reason")
                    if isinstance(fr, str):
                        return fr
        return None
    except Exception:
        return None


def _extract_usage(data: Mapping[str, Any] | None) -> dict[str, int] | None:
    try:
        if not isinstance(data, Mapping):
            return None
        u_val = data.get("usage")
        if not isinstance(u_val, Mapping):
            return None
        u_map: Mapping[str, Any] = cast("Mapping[str, Any]", u_val)
        out: dict[str, int] = {}
        for key in ("prompt_tokens", "completion_tokens", "total_tokens"):
            v_any = u_map.get(key)
            if isinstance(v_any, int):
                out[key] = v_any
        return out or None
    except Exception:
        return None


def _extract_bool_param(extra_params: dict[str, Any] | None, key: str, default: bool = False) -> bool:
    """
    Extract a boolean parameter from extra_params.

    Only accepts bool or str types for the value. If the value is not a bool or str,
    returns the default value. Strings are interpreted as True if they match
    ("true", "1", "yes", "on") (case-insensitive).
    """
    if not extra_params or key not in extra_params:
        return default
    value = extra_params[key]
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() in ("true", "1", "yes", "on")
    # For any other type, return the default value
    return default


def _extract_list_param(extra_params: dict[str, Any] | None, key: str) -> list[str] | None:
    """Extract a list parameter from extra_params."""
    if not extra_params or key not in extra_params:
        return None
    value = extra_params[key]
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str):
        # Support comma-separated strings
        return [item.strip() for item in value.split(",") if item.strip()]
    return None


def _has_function_calls(result_dict: dict[str, Any]) -> bool:
    """Check if the result contains function calls."""
    try:
        choices = result_dict.get("choices", [])
        if not choices:
            return False

        message = choices[0].get("message", {})
        tool_calls = message.get("tool_calls")
        return bool(tool_calls)
    except (KeyError, IndexError, AttributeError):
        return False


async def _handle_function_calls(result_dict: dict[str, Any]) -> list[dict[str, Any]]:
    """Handle function calls from the AI response."""
    tool_calls = list(_iter_tool_calls(result_dict))
    if not tool_calls:
        return []

    try:
        registry = get_tool_registry()
    except Exception as exc:  # pragma: no cover - defensive log
        logger.error("Unable to load tool registry: %s", exc)
        return []

    function_results: list[dict[str, Any]] = []
    for tool_call in tool_calls:
        result = await _process_tool_call(tool_call, registry)
        if result is not None:
            function_results.append(result)

    return function_results


def _iter_tool_calls(result_dict: dict[str, Any]) -> Iterable[Mapping[str, Any]]:
    try:
        choices = result_dict.get("choices", [])
        if not choices:
            return

        first_choice = choices[0]
        if not isinstance(first_choice, Mapping):
            return

        message = first_choice.get("message", {})
        if not isinstance(message, Mapping):
            return

        tool_calls = message.get("tool_calls", [])
        if not isinstance(tool_calls, Sequence):
            return

        for tool_call in tool_calls:
            if isinstance(tool_call, Mapping):
                yield tool_call
    except Exception as exc:  # pragma: no cover - defensive log
        logger.error("Error extracting tool calls: %s", exc)


async def _process_tool_call(tool_call: Mapping[str, Any], registry: Any) -> dict[str, Any] | None:
    try:
        tool_call_id, function_name, function_args = _parse_tool_call(tool_call)
    except ValueError as exc:
        function_block = tool_call.get("function")
        function_name = function_block.get("name") if isinstance(function_block, Mapping) else None
        logger.error("Invalid tool call payload: %s", exc)
        return {
            "tool_call_id": tool_call.get("id"),
            "function_name": function_name,
            "error": str(exc),
        }

    try:
        result = await registry.execute_tool(function_name, function_args)
        return {
            "tool_call_id": tool_call_id,
            "function_name": function_name,
            "result": result,
        }
    except Exception as exc:  # pragma: no cover - depends on tool implementations
        logger.error("Error executing function %s: %s", function_name, exc)
        return {
            "tool_call_id": tool_call_id,
            "function_name": function_name,
            "error": str(exc),
        }


def _parse_tool_call(tool_call: Mapping[str, Any]) -> tuple[str, str, Any]:
    function_block = tool_call.get("function")
    if not isinstance(function_block, Mapping):
        raise ValueError("Tool call missing function payload")

    function_name = function_block.get("name")
    if not function_name:
        raise ValueError("Tool call missing function name")

    tool_call_id = tool_call.get("id")
    if not tool_call_id:
        raise ValueError(f"Function '{function_name}' missing tool call identifier")

    raw_arguments = function_block.get("arguments", {})
    prepared_arguments = _prepare_function_arguments(raw_arguments, function_name)

    return tool_call_id, function_name, prepared_arguments


def _prepare_function_arguments(raw_arguments: Any, function_name: str) -> Any:
    if isinstance(raw_arguments, str):
        try:
            return json.loads(raw_arguments) if raw_arguments else {}
        except json.JSONDecodeError as exc:
            raise ValueError(f"Malformed JSON in function arguments for '{function_name}': {exc}") from exc
    return raw_arguments if raw_arguments is not None else {}


def _should_continue_conversation(extra_params: dict[str, Any] | None) -> bool:
    """Check if we should continue the conversation after function calls."""
    return _extract_bool_param(extra_params, "auto_continue", True)


def _extract_assistant_message(
    result_dict: dict[str, Any] | None,
) -> dict[str, Any] | None:
    """Extract the assistant message payload from the model response."""
    if not isinstance(result_dict, Mapping):
        return None

    try:
        choices = result_dict.get("choices", [])
        if not choices:
            return None

        first_choice = choices[0]
        if not isinstance(first_choice, Mapping):
            return None

        assistant_message = first_choice.get("message", {})
        if not isinstance(assistant_message, Mapping):
            return None

        return {
            "role": "assistant",
            "content": assistant_message.get("content"),
            "tool_calls": assistant_message.get("tool_calls"),
        }
    except (IndexError, AttributeError, TypeError, KeyError) as exc:
        logger.warning("Failed to extract assistant message: %s", exc)
        return None


def _serialize_result(result: Any) -> str:
    """Convert a tool result into a string payload for chat."""
    if isinstance(result, str):
        return result

    try:
        return json.dumps(result)
    except (TypeError, ValueError) as exc:
        logger.warning(
            "Failed to serialize result to JSON: %s. Using str(result) as fallback.",
            exc,
        )
        return str(result)


def _create_tool_message(func_result: Mapping[str, Any]) -> dict[str, Any] | None:
    """Create a tool role message from a tool execution result."""
    try:
        tool_call_id = func_result["tool_call_id"]
        function_name = func_result["function_name"]
    except KeyError as exc:
        logger.error("Function result missing required field: %s", exc)
        return None

    tool_message: dict[str, Any] = {
        "role": "tool",
        "tool_call_id": tool_call_id,
        "name": function_name,
        "content": (
            f"Error: {func_result['error']}" if "error" in func_result else _serialize_result(func_result.get("result"))
        ),
    }
    return tool_message


def _build_function_call_messages(
    result_dict: dict[str, Any], function_results: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    """Build messages to add function call results back to the conversation."""
    messages: list[dict[str, Any]] = []

    assistant_message = _extract_assistant_message(result_dict)
    if assistant_message:
        messages.append(assistant_message)

    for func_result in function_results:
        tool_message = _create_tool_message(func_result)
        if tool_message:
            messages.append(tool_message)

    return messages


@router.get("/v1/models", tags=["ai"])
async def list_models():
    """
    GET /v1/models
    - Returns available models from LM Studio via direct proxy
    """
    import httpx

    try:
        # Direct proxy to LM Studio
        async with httpx.AsyncClient() as client:
            response = await client.get("http://127.0.0.1:1234/v1/models")
            response.raise_for_status()
            return response.json()
    except httpx.ConnectError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="LM Studio is not available",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Failed to get models: {str(exc)}",
        ) from exc
