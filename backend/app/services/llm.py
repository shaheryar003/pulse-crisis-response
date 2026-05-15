"""LLM adapter. Real Gemini when GEMINI_API_KEY is set; deterministic mock otherwise.

The pipeline is designed so heuristic logic carries the load and the LLM only
adds enrichment (rationale prose, urdu translations, alternative-hypothesis
brainstorming). This keeps every test offline-deterministic.
"""
from __future__ import annotations

import os
import random
from dataclasses import dataclass


@dataclass
class LLMResponse:
    text: str
    model: str
    tokens: int = 0


class LLMAdapter:
    def __init__(self) -> None:
        self.api_key = os.getenv("GEMINI_API_KEY", "")
        self.real = bool(self.api_key)
        self._gemini = None
        if self.real:
            try:  # pragma: no cover - real LLM not exercised in tests
                import google.generativeai as genai

                genai.configure(api_key=self.api_key)
                self._gemini = genai
            except Exception:
                self.real = False

    def complete(self, prompt: str, *, model: str = "gemini-3-flash", temperature: float = 0.4, seed: int | None = None) -> LLMResponse:
        if self.real:  # pragma: no cover
            mdl = self._gemini.GenerativeModel(model)  # type: ignore[union-attr]
            out = mdl.generate_content(prompt, generation_config={"temperature": temperature})
            return LLMResponse(text=out.text or "", model=model)
        return self._mock(prompt, model=model, temperature=temperature, seed=seed)

    def _mock(self, prompt: str, *, model: str, temperature: float, seed: int | None) -> LLMResponse:
        rng = random.Random(seed if seed is not None else hash(prompt) & 0xFFFFFFFF)
        # Deterministic, prompt-sensitive mock: surfaces the prompt as part of a rationale.
        rationale = (
            "[mock-llm] Rationale derived from input signals. "
            "Heuristic agreement is high; no contradictions detected. "
            f"jitter={rng.random():.3f}."
        )
        return LLMResponse(text=rationale, model=f"mock-{model}", tokens=len(prompt) // 4)

    def translate(self, text: str, *, to: str = "ur") -> str:
        if not text:
            return ""
        if self.real:  # pragma: no cover
            return self.complete(f"Translate to {to} (Pakistan colloquial): {text}").text
        # Heuristic Urdu mock for common templates.
        mapping = {
            "flood": "سیلاب",
            "flooding": "سیلاب",
            "heat alert": "گرمی الرٹ",
            "heatwave": "گرمی کی لہر",
            "water main burst": "پانی کی لائن پھٹ گئی",
            "avoid": "گریز کریں",
            "stay indoors": "گھر کے اندر رہیں",
            "helpline": "ہیلپ لائن",
            "correction": "تصحیح",
            "shelter": "پناہ گاہ",
            "cooling center": "ٹھنڈک مرکز",
            "evacuate": "علاقہ خالی کریں",
            "ambulance": "ایمبولینس",
        }
        for en, ur in mapping.items():
            text = text.replace(en, ur)
        return text


_DEFAULT: LLMAdapter | None = None


def get_llm() -> LLMAdapter:
    global _DEFAULT
    if _DEFAULT is None:
        _DEFAULT = LLMAdapter()
    return _DEFAULT
