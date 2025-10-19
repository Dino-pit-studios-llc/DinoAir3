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
from pydantic.config import ConfigDict

from .errors import ServiceNotFound
from .health import HealthState

if TYPE_CHECKING:
    import builtins


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
    def register(self, desc: ServiceDescriptor | Mapping[str, Any]) -> ServiceDescriptor:
        """
        Register or replace by name.

        Accepts a ServiceDescriptor or plain dict. Returns stored descriptor.
        """
        sd = desc if isinstance(desc, ServiceDescriptor) else ServiceDescriptor(**dict(desc))
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
            return [d for d in self._services.values() if t in {x.lower() for x in d.tags}]

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
            try:
                desc = self._services[name]
            except KeyError as exc:
                raise ServiceNotFound(f"Service '{name}' not found") from exc

            info: dict[str, Any]
            if isinstance(state_or_info, Mapping):
                # Normalize provided dict
                info = dict(state_or_info)
                s = info.get("state")
                if isinstance(s, HealthState):
                    info["state"] = s.value
                elif isinstance(s, str):
                    info["state"] = s.upper()
                # best-effort numeric coercion
                if "latency_ms" in info:
                    with suppress(Exception):
                        info["latency_ms"] = float(info["latency_ms"])
            else:
                # Build dict from discrete values
                info = {"state": state_or_info.value}
                if latency_ms is not None:
                    info["latency_ms"] = float(latency_ms)
            if error is not None:
                info["error"] = str(error)
            desc.health = info
            return desc


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
    from .health import HealthState as _HealthState

    services = _load_services_safely(services_file)

    for s in services:
        _register_service_safely(registry, s, _HealthState)

    return registry


def _load_services_safely(services_file: str) -> list:
    """Load services from file, returning empty list on error.

    Args:
        services_file: Path to services configuration file

    Returns:
        List of service descriptors (empty list on error)
    """
    from .config import load_services_from_file

    try:
        return load_services_from_file(services_file)
    except Exception:
        return []


def _register_service_safely(registry: ServiceRegistry, service: Any, health_state_cls: Any) -> None:
    """Register a service and validate its health if it's an LM Studio service.

    Args:
        registry: Service registry
        service: Service descriptor to register
        health_state_cls: HealthState class
    """
    try:
        registry.register(service)
    except Exception:
        return

    # Minimal reachability check for LM Studio services
    if not _is_lmstudio_service(service):
        return

    _validate_and_probe_service(registry, service, health_state_cls)


def _validate_and_probe_service(registry: ServiceRegistry, service: Any, health_state_cls: Any) -> None:
    """Validate service configuration and probe its health.

    Args:
        registry: Service registry
        service: Service descriptor
        health_state_cls: HealthState class
    """
    base_url = _extract_base_url(service)
    if not base_url:
        _mark_service_degraded(registry, service.name, "missing base_url")
        return

    # Probe service health
    is_healthy = _probe_service_health(base_url)
    _update_service_health(registry, service.name, is_healthy, health_state_cls)


def _is_lmstudio_service(service: Any) -> bool:
    """Check if service is an LM Studio service.

    Args:
        service: Service descriptor to check

    Returns:
        True if service is LM Studio type
    """
    adapter_kind = getattr(service, "adapter", None)
    return isinstance(adapter_kind, str) and adapter_kind.strip().lower() == "lmstudio"


def _extract_base_url(service: Any) -> str | None:
    """Extract base URL from service configuration.

    Args:
        service: Service descriptor

    Returns:
        Base URL string or None if not found
    """
    with suppress(Exception):
        cfg = getattr(service, "adapter_config", {}) or {}
        base_url = str(cfg.get("base_url") or "").strip() or None
        return base_url
    return None


def _mark_service_degraded(registry: ServiceRegistry, service_name: str, error_msg: str) -> None:
    """Mark service as degraded with error message.

    Args:
        registry: Service registry
        service_name: Name of the service
        error_msg: Error message to record
    """
    from .health import HealthState as _HealthState

    with suppress(Exception):
        registry.update_health(service_name, _HealthState.DEGRADED, latency_ms=0, error=error_msg)


def _probe_service_health(base_url: str) -> bool:
    """Probe service health using HTTP HEAD/GET requests.

    Args:
        base_url: Base URL to probe

    Returns:
        True if service responds successfully
    """
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


def _update_service_health(
    registry: ServiceRegistry,
    service_name: str,
    is_healthy: bool,
    health_state_cls: Any,
) -> None:
    """Update service health status in registry.

    Args:
        registry: Service registry
        service_name: Name of the service
        is_healthy: Whether service is healthy
        health_state_cls: HealthState class
    """
    with suppress(Exception):
        registry.update_health(
            service_name,
            health_state_cls.HEALTHY if is_healthy else health_state_cls.DEGRADED,
            latency_ms=0,
        )
