"""
Local Transformer Model Implementation for the Pseudocode Translator

This module provides a HuggingFace Transformers-based model implementation
for local code generation using models like CodeGen, StarCoder, etc.
"""

import logging
from pathlib import Path
from typing import Any

import torch

from .base_model import (
    BaseTranslationModel,
    ModelCapabilities,
    ModelMetadata,
    OutputLanguage,
    TranslationConfig,
    TranslationResult,
)
from .model_factory import ModelPriority, register_model

logger = logging.getLogger(__name__)

# Try to import transformers
try:
    from transformers import (
        AutoModelForCausalLM,
        AutoTokenizer,
        GenerationConfig,
        StoppingCriteria,
        StoppingCriteriaList,
    )

    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False
    AutoModelForCausalLM = None
    AutoTokenizer = None
    GenerationConfig = None
    StoppingCriteria = None
    StoppingCriteriaList = None


class CodeStoppingCriteria:
    """Custom stopping criteria for code generation"""

    def __init__(self, tokenizer, stop_tokens):
        self.tokenizer = tokenizer
        self.stop_tokens = stop_tokens

    def __call__(self, input_ids, scores, **kwargs):
        # Check if any stop token is generated
        return any(input_ids[0][-1] == stop_token for stop_token in self.stop_tokens)


@register_model(
    name="local-transformer",
    aliases=["huggingface", "hf", "transformer", "codegen", "starcoder"],
    priority=ModelPriority.MEDIUM,
)
class LocalTransformerModel(BaseTranslationModel):
    """
    Local transformer model using HuggingFace Transformers

    Supports various code generation models like CodeGen, StarCoder,
    CodeT5, etc. for offline code generation.
    """

    def __init__(self, config: dict[str, Any]):
        """
        Initialize local transformer model

        Args:
            config: Model configuration dictionary
        """
        super().__init__(config)

        if not TRANSFORMERS_AVAILABLE:
            raise ImportError(
                "transformers package is required. Install with: pip install transformers torch"
            )

        # Set default configuration
        self.config.setdefault("model_name", "Salesforce/codegen-350M-mono")
        self.config.setdefault("device", "cuda" if torch.cuda.is_available() else "cpu")
        self.config.setdefault("torch_dtype", "float16" if torch.cuda.is_available() else "float32")
        self.config.setdefault("temperature", 0.3)
        self.config.setdefault("top_p", 0.9)
        self.config.setdefault("top_k", 40)
        self.config.setdefault("max_length", 2048)
        self.config.setdefault("do_sample", True)
        self.config.setdefault("num_return_sequences", 1)
        self.config.setdefault("load_in_8bit", False)
        self.config.setdefault("trust_remote_code", False)
        self.config.setdefault("model_revision", "main")

        self._model = None
        self._tokenizer = None

        # Language mapping for model selection
        self.language_suffixes = {
            OutputLanguage.PYTHON: "-python",
            OutputLanguage.JAVASCRIPT: "-javascript",
            OutputLanguage.JAVA: "-java",
            OutputLanguage.CPP: "-cpp",
            OutputLanguage.GO: "-go",
            OutputLanguage.RUST: "-rust",
            OutputLanguage.PHP: "-php",
            OutputLanguage.RUBY: "-ruby",
            OutputLanguage.SQL: "-sql",
            OutputLanguage.BASH: "-shell",
        }

    @property
    def metadata(self) -> ModelMetadata:
        """Get model metadata"""
        return ModelMetadata(
            name="local-transformer",
            version=self.config["model_name"].split("/")[-1],
            supported_languages=list(OutputLanguage),
            description=(
                "Local transformer model using HuggingFace Transformers. Supports various code generation models for offline use."
            ),
            author="HuggingFace/Community",
            license="Various (model-dependent)",
            model_type="transformer",
            size_gb=self._estimate_model_size(),
            requires_gpu=self.config["device"] == "cuda",
            supports_streaming=True,
            max_context_length=self.config["max_length"],
        )

    @property
    def capabilities(self) -> ModelCapabilities:
        """Get model capabilities"""
        return ModelCapabilities(
            translate_instruction=True,
            validate_input=True,
            get_capabilities=True,
            supports_refinement=True,
            supports_batch_processing=True,
            supports_context_aware=True,
            supports_code_completion=True,
            supports_error_correction=False,
            tokens_per_second=self._estimate_speed(),
            max_batch_size=4,
            optimal_temperature=0.3,
            min_memory_gb=2.0,
            recommended_memory_gb=8.0,
        )

    def initialize(self, model_path: Path | None = None, **kwargs) -> None:
        """
        Initialize the transformer model

        Args:
            model_path: Optional local path to model
            **kwargs: Additional initialization parameters
        """
        model_name_or_path = str(model_path) if model_path else self.config["model_name"]
        logger.info("Loading transformer model: %s", model_name_or_path)

        try:
            # Determine torch dtype
            torch_dtype = getattr(torch, self.config["torch_dtype"])

            # Load tokenizer
            self._tokenizer = AutoTokenizer.from_pretrained(  # nosec B615
                model_name_or_path,
                revision=self.config["model_revision"],
                trust_remote_code=self.config["trust_remote_code"],
            )

            # Set padding token if not present
            if self._tokenizer.pad_token is None:
                self._tokenizer.pad_token = self._tokenizer.eos_token

            # Load model
            load_kwargs = {
                "torch_dtype": torch_dtype,
                "device_map": ("auto" if self.config["device"] == "cuda" else None),
                "trust_remote_code": self.config["trust_remote_code"],
                "revision": self.config["model_revision"],
            }

            if self.config["load_in_8bit"]:
                load_kwargs["load_in_8bit"] = True

            self._model = AutoModelForCausalLM.from_pretrained(  # nosec B615
                model_name_or_path, **load_kwargs
            )

            # Move to device if not using device_map
            if self.config["device"] != "cuda" or not load_kwargs.get("device_map"):
                self._model = self._model.to(self.config["device"])

            # Set to eval mode
            self._model.eval()

            self._initialized = True
            logger.info("Transformer model loaded successfully")

        except Exception as e:
            raise RuntimeError(f"Failed to load transformer model: {str(e)}")

    def translate(
        self,
        instruction: str,
        config: TranslationConfig | None = None,
        context: dict[str, Any] | None = None,
    ) -> TranslationResult:
        """
        Translate instruction using local transformer

        Args:
            instruction: Natural language instruction
            config: Translation configuration
            context: Optional context

        Returns:
            TranslationResult with generated code
        """
        if not self._initialized:
            raise RuntimeError("Model not initialized")

        # Use default config if not provided
        if config is None:
            config = TranslationConfig()

        try:
            # Build prompt
            prompt = LocalTransformerModel._build_prompt(instruction, config, context)

            # Tokenize
            inputs = self._tokenizer(
                prompt,
                return_tensors="pt",
            ).to(self.config["device"])

            # Generate
            with torch.no_grad():
                outputs = self._model.generate(
                    **inputs,
                    max_length=config.max_tokens or self.config["max_length"],
                    temperature=config.temperature or self.config["temperature"],
                    top_p=self.config["top_p"],
                    top_k=self.config["top_k"],
                    do_sample=self.config["do_sample"],
                    num_return_sequences=self.config["num_return_sequences"],
                    pad_token_id=self._tokenizer.pad_token_id,
                    eos_token_id=self._tokenizer.eos_token_id,
                )

            # Decode output
            generated_text = self._tokenizer.decode(outputs[0], skip_special_tokens=True)

            # Remove prompt from output
            if generated_text.startswith(prompt):
                generated_text = generated_text[len(prompt) :].strip()

            return TranslationResult(
                success=True,
                code=generated_text,
                language=config.target_language,
                confidence=1.0,
                metadata={
                    "prompt": prompt,
                    "model_name": self.config["model_name"],
                    "device": self.config["device"],
                },
            )
        except Exception as e:
            raise RuntimeError(f"Failed to translate instruction: {str(e)}")

    @staticmethod
    def _build_prompt(
        instruction: str,
        config: TranslationConfig,
        context: dict[str, Any] | None = None,
    ) -> str:
        """Build prompt for the model"""
        lang = config.output_language.value.upper()
        prompt = f"# Task: Convert the following instruction to {lang} code\n"
        prompt += f"# Instruction: {instruction}\n"

        if context:
            # Only include relevant fields and format context for clarity
            relevant_keys = ["filename", "function_name", "dependencies", "description"]
            formatted_context = "\n".join(
                f"#   {key}: {context[key]}"
                for key in relevant_keys
                if key in context and context[key] is not None
            )
            if formatted_context:
                prompt += "# Context:\n" + formatted_context + "\n"

        prompt += f"# {lang} Code:\n"
        return prompt

    def _estimate_model_size(self) -> float:
        """Estimate model size in GB"""
        model_name = self.config["model_name"].lower()
        if "350m" in model_name:
            return 1.4
        if "2b" in model_name or "1b" in model_name:
            return 4.0
        if "6b" in model_name:
            return 12.0
        if "16b" in model_name or "15b" in model_name:
            return 32.0
        return 2.0

    def _estimate_speed(self) -> int:
        """Estimate tokens per second"""
        if self.config["device"] == "cuda":
            return 50
        return 10
