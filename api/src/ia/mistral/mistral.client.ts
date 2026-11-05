import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ErroProvedorIA } from '../ia.types';

const TENTATIVAS = 3;

@Injectable()
export class MistralClient {
  private readonly urlBase: string;
  private readonly chave: string | undefined;

  constructor(config: ConfigService) {
    this.urlBase = (config.get<string>('MISTRAL_BASE_URL') || 'https://api.mistral.ai/v1').replace(/\/+$/, '');
    this.chave = config.get<string>('MISTRAL_API_KEY') || undefined;
    if (!this.chave) {
      new Logger(MistralClient.name).warn('MISTRAL_API_KEY não configurada: os editais vão falhar ao processar.');
    }
  }

  get configurado(): boolean {
    return Boolean(this.chave);
  }

  async post<T>(caminho: string, corpo: unknown, timeoutMs: number): Promise<T> {
    if (!this.chave) throw new ErroProvedorIA('mistral', 'MISTRAL_API_KEY não configurada.');

    for (let tentativa = 1; ; tentativa++) {
      let resposta: Response;
      try {
        resposta = await fetch(`${this.urlBase}${caminho}`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${this.chave}`,
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
          body: JSON.stringify(corpo),
          signal: AbortSignal.timeout(timeoutMs),
        });
      } catch (erro) {
        if (tentativa < TENTATIVAS) {
          await esperar(tentativa);
          continue;
        }
        throw new ErroProvedorIA('mistral', `Falha de rede em ${caminho}: ${(erro as Error).message}`);
      }

      if (resposta.ok) return (await resposta.json()) as T;

      const detalhe = (await resposta.text()).slice(0, 500);
      const temporario = resposta.status === 429 || resposta.status >= 500;
      if (temporario && tentativa < TENTATIVAS) {
        await esperar(tentativa, resposta.headers.get('retry-after'));
        continue;
      }
      throw new ErroProvedorIA('mistral', `${caminho} respondeu ${resposta.status}: ${detalhe}`, resposta.status);
    }
  }
}

function esperar(tentativa: number, retryAfter?: string | null): Promise<void> {
  const segundos = Number(retryAfter);
  const ms = Number.isFinite(segundos) && segundos > 0 ? segundos * 1000 : 1000 * 2 ** tentativa;
  return new Promise((resolver) => setTimeout(resolver, Math.min(ms, 30_000)));
}
