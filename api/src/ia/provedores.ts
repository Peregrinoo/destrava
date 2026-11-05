import { Type } from '@nestjs/common';
import { LlmProvider, OcrProvider } from './ia.types';
import { MistralLlmProvider } from './mistral/mistral-llm.provider';
import { MistralOcrProvider } from './mistral/mistral-ocr.provider';

export const PROVEDORES_OCR: Record<string, Type<OcrProvider>> = {
  mistral: MistralOcrProvider,
};

export const PROVEDORES_LLM: Record<string, Type<LlmProvider>> = {
  mistral: MistralLlmProvider,
};
