import { Module, Type } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ModuleRef } from '@nestjs/core';
import { LlmProvider, OcrProvider } from './ia.types';
import { PROVEDORES_LLM, PROVEDORES_OCR } from './provedores';

function escolher<T>(token: abstract new (...args: never[]) => T, variavel: string, opcoes: Record<string, Type<T>>) {
  return {
    provide: token,
    inject: [ConfigService, ModuleRef],
    useFactory: (config: ConfigService, modulo: ModuleRef): Promise<T> => {
      const nome = config.get<string>(variavel)?.trim().toLowerCase();
      const disponiveis = Object.keys(opcoes).join(', ');
      if (!nome) {
        throw new Error(`Defina ${variavel} no .env. Opções: ${disponiveis}.`);
      }
      const classe = opcoes[nome];
      if (!classe) {
        throw new Error(`${variavel}="${nome}" não é suportado. Opções: ${disponiveis}.`);
      }
      return modulo.create(classe);
    },
  };
}

@Module({
  providers: [
    escolher(OcrProvider, 'OCR_PROVIDER', PROVEDORES_OCR),
    escolher(LlmProvider, 'LLM_PROVIDER', PROVEDORES_LLM),
  ],
  exports: [OcrProvider, LlmProvider],
})
export class IaModule {}
