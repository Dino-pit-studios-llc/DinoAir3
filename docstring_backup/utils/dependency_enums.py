"""
Dependency Injection Enums

This module defines enums used in the dependency injection system,
including lifecycle scopes and dependency states.
"""

from enum import Enum


class Scope(Enum):
    """Dependency lifecycle scopes."""

    singleton = "singleton"  # One instance for entire app
    transient = "transient"  # New instance every time
    scoped = "scoped"  # One instance per scope/request


class LifecycleState(Enum):
    """States a dependency can be in."""

    registered = "registered"
    creating = "creating"
    created = "created"
    disposing = "disposing"
    disposed = "disposed"
