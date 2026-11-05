import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ErroProvedorIA, LlmProvider, PedidoJson } from '../ia.types';
import { MistralClient } from './mistral.client';

interface RespostaChat {
  choices?: {
    finish_reason?: string;
    message?: { content?: string | { type?: string; text?: string }[] | null };
  }[];
}

@Injectable()
export class MistralLlmProvider extends LlmProvider {
  readonly nome = 'mistral';
  private readonly modelo: string;

  constructor(
    private readonly cliente: MistralClient,
    config: ConfigService,
  ) {
    super();
    this.modelo = config.get<string>('MISTRAL_LLM_MODEL') || 'mistral-small-latest';
  }

  async gerarJson(pedido: PedidoJson): Promise<unknown> {
    let resposta: RespostaChat;
    try {
      resposta = await this.chamar(
        [
          { role: 'system', content: pedido.instrucoes },
          { role: 'user', content: pedido.entrada },
        ],
        { type: 'json_schema', json_schema: { name: pedido.nomeSchema, schema: pedido.schema, strict: true } },
      );
    } catch (erro) {
      const schemaRecusado = erro instanceof ErroProvedorIA && (erro.status === 400 || erro.status === 422);
      if (!schemaRecusado) throw erro;
      resposta = await this.chamar(
        [
          {
            role: 'system',
            content: `${pedido.instrucoes}\n\nResponda apenas com um JSON válido que siga este JSON Schema:\n${JSON.stringify(pedido.schema)}`,
          },
          { role: 'user', content: pedido.entrada },
        ],
        { type: 'json_object' },
      );
    }

    const escolha = resposta.choices?.[0];
    if (escolha?.finish_reason === 'length') {
      throw new ErroProvedorIA('mistral', 'A resposta do modelo foi cortada por limite de tamanho.');
    }

    const conteudo = escolha?.message?.content;
    const texto = typeof conteudo === 'string'
      ? conteudo
      : Array.isArray(conteudo)
        ? conteudo.map((parte) => parte.text ?? '').join('')
        : '';

    try {
      return JSON.parse(texto);
    } catch {
      throw new ErroProvedorIA('mistral', 'O modelo não devolveu um JSON válido.');
    }
  }

  private chamar(messages: { role: string; content: string }[], responseFormat: Record<string, unknown>) {
    return this.cliente.post<RespostaChat>(
      '/chat/completions',
      { model: this.modelo, temperature: 0, messages, response_format: responseFormat },
      180_000,
    );
  }
}
