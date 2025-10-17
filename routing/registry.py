"""
Service registry and descriptor model for DinoAir core_router.

Provides:
- ServiceDescriptor: pydantic model describing a service.
- ServiceRegistry: in-memory registry with CRUD and lookup utilities.
"""

from __future__ import annotations

from collections.abc import Mapping
from contextlib import suppress
from threading import Lock
from typing import TYPE_CHECKING, Any

from pydantic import BaseModel, Field
from pydantic import ValidationError as PydanticValidationError
from pydantic.config import ConfigDict

from .errors import ServiceNotFound
from .health import HealthState

if TYPE_CHECKING:
    import builtins

# Prefer enhanced logger; fallback to stdlib logging
try:
    from utils.enhanced_logger import get_logger as _get_logger
except Exception:  # pragma: no cover
    import logging as _logging

    def _get_logger(name: str):
        return _logging.getLogger(name)


logger = _get_logger(__name__)


class ServiceDescriptor(BaseModel):
    """Pydantic model for a service's static config and runtime hints."""

    name: str
    version: str
    tags: list[str] = Field(default_factory=list)

    # JSON-schema-like dicts (validated elsewhere)
    input_schema: dict[str, Any] | None = None
    output_schema: dict[str, Any] | None = None

    # Adapter wiring
    adapter: str  # e.g. "local_python" | "lmstudio"
    adapter_config: dict[str, Any] = Field(default_factory=dict)

    # Optional operational knobs and metadata
    # e.g. {"qps": 5} or {"rpm": 300}
    rate_limits: dict[str, Any] | None = None
    deps: list[str] | None = None
    # health snapshot: {"state": "...", "latency_ms": number}
    health: dict[str, Any] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)

    # Pydantic v2 configuration
    model_config = ConfigDict(validate_assignment=True, frozen=False)


class ServiceRegistry:
    """
    Thread-safe in-memory registry for ServiceDescriptor objects.

    - Services are keyed by unique 'name'.
    - Registering an existing name overwrites the previous descriptor.
    """

    def __init__(self) -> None:
        self._lock: Lock = Lock()
        self._services: dict[str, ServiceDescriptor] = {}

    # -------------------------
    # CRUD / Lookup
    # -------------------------
    def register(
        self, desc: ServiceDescriptor | Mapping[str, Any]
    ) -> ServiceDescriptor:
        """
        Register or replace by name.

        Accepts a ServiceDescriptor or plain dict. Returns stored descriptor.
        """
        sd = (
            desc
            if isinstance(desc, ServiceDescriptor)
            else ServiceDescriptor(**dict(desc))
        )
        with self._lock:
            self._services[sd.name] = sd
            return sd

    def unregister(self, name: str) -> bool:
        """Remove a service by name. True if removed, else False."""
        with self._lock:
            return self._services.pop(name, None) is not None

    def get_by_name(self, name: str) -> ServiceDescriptor:
        """
        Retrieve a descriptor by unique name.

        Raises:
            ServiceNotFound: if the service does not exist.
        """
        with self._lock:
            try:
                return self._services[name]
            except KeyError as exc:
                raise ServiceNotFound(f"Service '{name}' not found") from exc

    def get_by_tag(self, tag: str) -> builtins.list[ServiceDescriptor]:
        """Return services containing the tag (case-insensitive)."""
        t = (tag or "").lower()
        with self._lock:
            return [
                d for d in self._services.values() if t in {x.lower() for x in d.tags}
            ]

    def list(self) -> builtins.list[ServiceDescriptor]:
        """Return all registered services."""
        with self._lock:
            return list(self._services.values())

    # -------------------------
    # Health
    # -------------------------
    def update_health(
        self,
        name: str,
        state_or_info: HealthState | Mapping[str, Any],
        latency_ms: int | float | None = None,
        error: str | None = None,
    ) -> ServiceDescriptor:
        """
        Update health snapshot for a service.

        Forms:
        - update_health(name, {"state": HealthState|str, "latency_ms": n, ...})
        - update_health(name, HealthState.X, latency_ms=..., error=...)

        Returns the updated ServiceDescriptor.
        """
        with self._lock:
            desc = self._get_service_descriptor(name)
            info = self._build_health_info(state_or_info, latency_ms, error)
            desc.health = info
            return desc

    def _get_service_descriptor(self, name: str) -> ServiceDescriptor:
        """Get service descriptor by name or raise ServiceNotFound."""
        try:
            return self._services[name]
        except KeyError as exc:
            raise ServiceNotFound(f"Service '{name}' not found") from exc

    def _build_health_info(
        self,
        state_or_info: HealthState | Mapping[str, Any],
        latency_ms: int | float | None,
        error: str | None,
    ) -> dict[str, Any]:
        """Build health info dict from parameters."""
        if isinstance(state_or_info, Mapping):
            return self._normalize_health_dict(state_or_info)
        return self._create_health_dict(state_or_info, latency_ms, error)

    @staticmethod
    def _normalize_health_dict(state_dict: Mapping[str, Any]) -> dict[str, Any]:
        """Normalize health info from provided dict."""
        info = dict(state_dict)
        s = info.get("state")
        if isinstance(s, HealthState):
            info["state"] = s.value
        elif isinstance(s, str):
            info["state"] = s.upper()
        # best-effort numeric coercion
        if "latency_ms" in info:
            with suppress(Exception):
                info["latency_ms"] = float(info["latency_ms"])
        return info

    @staticmethod
    def _create_health_dict(
        state: HealthState,
        latency_ms: int | float | None,
        error: str | None,
    ) -> dict[str, Any]:
        """Create health info dict from discrete values."""
        info = {"state": state.value}
        if latency_ms is not None:
            info["latency_ms"] = float(latency_ms)
        if error is not None:
            info["error"] = str(error)
        return info


# -------------------------
# Auto-registration helper (soft validation)
# -------------------------


def auto_register_from_config_and_env(
    registry: ServiceRegistry,
    services_file: str = "config/services.lmstudio.yaml",
) -> ServiceRegistry:
    """
    Load services from the default YAML (and apply env overrides) and register
    them into the provided registry. Soft-validate LM Studio base URL(s) with
    a short HEAD/GET probe and update health accordingly. Never raises.

    Returns the provided registry for chaining.
    """
    from .config import load_services_from_file

    services = _load_services_safely(services_file)

    for s in services:
        if not _try_register_service(registry, s):
            continue

        _validate_lmstudio_health(registry, s)

    return registry


def _load_services_safely(services_file: str) -> list:
    """Load services from file, returning empty list on error"""
    from .config import load_services_from_file

    try:
        return load_services_from_file(services_file)
    except (ValueError, RuntimeError, OSError) as e:
        logger.debug("auto-register load failed for '%s': %s", services_file, e)
        return []


def _try_register_service(registry: ServiceRegistry, service: Any) -> bool:
    """Try to register service, return True if successful"""
    try:
        registry.register(service)
        return True
    except (ValueError, TypeError, KeyError) as e:
        svc = getattr(service, "name", "<unknown>")
        logger.debug("auto-register skipped '%s': %s", svc, e)
        return False
    except PydanticValidationError as e:
        svc = getattr(service, "name", "<unknown>")
        logger.debug("auto-register validation failed '%s': %s", svc, e)
        return False


def _validate_lmstudio_health(registry: ServiceRegistry, service: Any) -> None:
    """Perform health check for LM Studio services"""
    if not _is_lmstudio_service(service):
        return

    base_url = _extract_base_url(service)
    if not base_url:
        _mark_service_degraded(registry, service.name, "missing base_url")
        return

    is_healthy = _check_service_reachability(base_url)
    _update_service_health(registry, service.name, is_healthy)


def _is_lmstudio_service(service: Any) -> bool:
    """Check if service is an LM Studio adapter"""
    adapter_kind = getattr(service, "adapter", None)
    return isinstance(adapter_kind, str) and adapter_kind.strip().lower() == "lmstudio"


def _extract_base_url(service: Any) -> str | None:
    """Extract base URL from service adapter config"""
    with suppress(Exception):
        cfg = getattr(service, "adapter_config", {}) or {}
        return str(cfg.get("base_url") or "").strip() or None
    return None


def _check_service_reachability(base_url: str) -> bool:
    """Check if service is reachable via HEAD or GET request"""
    import httpx

    # Try HEAD first
    with suppress(Exception):
        r = httpx.head(base_url, timeout=0.8)
        if 200 <= r.status_code < 300:
            return True

    # Fallback to GET
    with suppress(Exception):
        r2 = httpx.get(base_url, timeout=0.8)
        if 200 <= r2.status_code < 300:
            return True

    return False


def _mark_service_degraded(
    registry: ServiceRegistry, service_name: str, error: str
) -> None:
    """Mark service as degraded with error message"""
    with suppress(Exception):
        registry.update_health(
            service_name, HealthState.DEGRADED, latency_ms=0, error=error
        )


def _update_service_health(
    registry: ServiceRegistry, service_name: str, is_healthy: bool
) -> None:
    """Update service health status"""
    with suppress(Exception):
        health_state = HealthState.HEALTHY if is_healthy else HealthState.DEGRADED
        registry.update_health(service_name, health_state, latency_ms=0)
