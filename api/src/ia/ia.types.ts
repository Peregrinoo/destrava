export interface PaginaTexto {
  numero: number;
  texto: string;
}

export interface PedidoJson {
  instrucoes: string;
  entrada: string;
  nomeSchema: string;
  schema: Record<string, unknown>;
}

export abstract class OcrProvider {
  abstract readonly nome: string;
  abstract extrairTexto(pdf: Buffer): Promise<PaginaTexto[]>;
}

export abstract class LlmProvider {
  abstract readonly nome: string;
  abstract gerarJson(pedido: PedidoJson): Promise<unknown>;
}

export class ErroProvedorIA extends Error {
  constructor(
    readonly provedor: string,
    message: string,
    readonly status?: number,
  ) {
    super(message);
    this.name = 'ErroProvedorIA';
  }
}
