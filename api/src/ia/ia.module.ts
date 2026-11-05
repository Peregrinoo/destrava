import { Module, Type } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LlmProvider, OcrProvider } from './ia.types';
import { MistralLlmProvider } from './mistral/mistral-llm.provider';
import { MistralOcrProvider } from './mistral/mistral-ocr.provider';
import { MistralClient } from './mistral/mistral.client';

const PROVEDORES_OCR: Record<string, Type<OcrProvider>> = {
  mistral: MistralOcrProvider,
};

const PROVEDORES_LLM: Record<string, Type<LlmProvider>> = {
  mistral: MistralLlmProvider,
};

function escolher<T>(token: abstract new (...args: never[]) => T, variavel: string, opcoes: Record<string, Type<T>>) {
  const nomes = Object.keys(opcoes);
  return {
    provide: token,
    inject: [ConfigService, ...nomes.map((nome) => opcoes[nome])],
    useFactory: (config: ConfigService, ...instancias: T[]): T => {
      const nome = config.get<string>(variavel) || 'mistral';
      const indice = nomes.indexOf(nome);
      if (indice === -1) {
        throw new Error(`${variavel}="${nome}" não é suportado. Opções: ${nomes.join(', ')}.`);
      }
      return instancias[indice];
    },
  };
}

@Module({
  providers: [
    MistralClient,
    MistralOcrProvider,
    MistralLlmProvider,
    escolher(OcrProvider, 'OCR_PROVIDER', PROVEDORES_OCR),
    escolher(LlmProvider, 'LLM_PROVIDER', PROVEDORES_LLM),
  ],
  exports: [OcrProvider, LlmProvider],
})
export class IaModule {}
