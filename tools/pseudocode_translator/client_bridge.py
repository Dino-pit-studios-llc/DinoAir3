"""Client bridge integration point for the pseudocode translator.

The runtime is intentionally headless. Downstream applications should provide
platform-specific adapters that consume translator callbacks or streaming
updates. This placeholder keeps the public surface discoverable without
introducing direct UI dependencies.
"""

from __future__ import annotations

__all__: list[str] = []
