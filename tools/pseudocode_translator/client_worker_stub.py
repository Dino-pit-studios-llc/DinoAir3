"""Client-facing worker stub for the pseudocode translator.

Legacy desktop workers relied on Qt event loops. The translator now exposes
pure callback hooks so custom clients can implement their own threading or
message-passing strategies. This module exists solely to document that shift.
"""

from __future__ import annotations

__all__: list[str] = []
