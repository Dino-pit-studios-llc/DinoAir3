"""
Enums and constants for DinoAir
Centralized location for application constants
"""

from enum import Enum, auto
from typing import Any


class app_state(Enum):
    """Application state enumeration"""

    starting = auto()
    running = auto()
    paused = auto()
    shutting_down = auto()
    error = auto()


class database_state(Enum):
    """Database state enumeration"""

    connected = auto()
    disconnected = auto()
    initializing = auto()
    error = auto()
    backup_in_progress = auto()


class note_status(Enum):
    """Note status enumeration"""

    draft = auto()
    active = auto()
    archived = auto()
    deleted = auto()


class input_type(Enum):
    """Input type enumeration for input processing"""

    text = auto()
    voice = auto()
    file = auto()
    clipboard = auto()


class processing_stage(Enum):
    """Input processing stage enumeration"""

    validation = auto()
    escaping = auto()
    pattern_notify = auto()
    profanity_filter = auto()
    intent_classifier = auto()
    translation = auto()
    complete = auto()


class agent_type(Enum):
    """AI Agent type enumeration"""

    llm_wrapper = auto()
    orchestrator = auto()
    translator = auto()
    classifier = auto()


class tool_type(Enum):
    """Tool type enumeration"""

    memory_tool = auto()
    timer_tool = auto()
    code_agent = auto()
    file_tool = auto()


class ui_theme(Enum):
    """UI Theme enumeration"""

    light = "light"
    dark = "dark"
    auto = "auto"


class log_level(Enum):
    """Logging level enumeration"""

    debug = "debug"
    info = "info"
    warning = "warning"
    error = "error"
    critical = "critical"


class Enums:
    """Container class for all application enums with utility methods for validation and listing."""

    app_state = app_state
    database_state = database_state
    note_status = note_status
    input_type = input_type
    processing_stage = processing_stage
    agent_type = agent_type
    tool_type = tool_type
    ui_theme = ui_theme
    log_level = log_level

    @classmethod
    def list_enum_names(cls) -> list[str]:
        """Return a list of all enum class names in this container."""
        return [
            name for name in dir(cls) if isinstance(getattr(cls, name), type) and issubclass(getattr(cls, name), Enum)
        ]

    @staticmethod
    def is_valid_value(enum_name: str, value: Any) -> bool:
        """Validate if a value is valid for the specified enum.

        Args:
            enum_name (str): The name of the enum class (e.g., 'app_state').
            value: The value to validate.

        Returns:
            bool: True if the value is valid for the enum, False otherwise.
        """
        if not isinstance(enum_name, str) or enum_name is None:
            return False

        enum_class = getattr(Enums, enum_name, None)
        if enum_class and issubclass(enum_class, Enum):
            return isinstance(value, enum_class)
        return False
