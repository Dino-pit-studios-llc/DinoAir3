"""
LLM Translation Service

This service provides LLM-first translation approach using the model service
for pseudocode to programming language translation.
"""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from utils.shutdown_protocols import ShutdownMixin

from .error_handler import ErrorHandler

if TYPE_CHECKING:
    from .model_service import ModelService
    from .translation_pipeline import TranslationContext, TranslationResult

logger = logging.getLogger(__name__)


class LLMTranslationService(ShutdownMixin):
    """
    Service for LLM-first translation approach.

    Uses language models to directly translate pseudocode to target programming
    languages with minimal preprocessing.
    """

    def __init__(self, model_service: ModelService, error_handler: ErrorHandler | None = None):
        super().__init__()
        self.model_service = model_service
        self.error_handler = error_handler or ErrorHandler(logger_name=__name__)

        # Statistics
        self._successful_translations = 0
        self._failed_translations = 0
        self._total_processing_time = 0.0

        logger.debug("LLMTranslationService initialized")

    def translate(self, context: TranslationContext) -> TranslationResult:
        """
        Translate pseudocode using LLM-first approach.

        Args:
            context: Translation context with input text and metadata

        Returns:
            TranslationResult with translated code or errors
        """
        from .translation_pipeline import TranslationResult

        logger.debug("Starting LLM translation for ID: %s", context.translation_id)

        # Validate input
        is_valid, validation_error = self.model_service.validate_input(context.input_text)
        if not is_valid:
            self._failed_translations += 1
            return TranslationResult(
                success=False,
                code=None,
                errors=[f"Input validation failed: {validation_error}"],
                warnings=[],
            )
