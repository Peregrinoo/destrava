import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OcrProvider, PaginaTexto } from '../ia.types';
import { MistralClient } from './mistral.client';

interface RespostaOcr {
  pages?: { index: number; markdown?: string }[];
}

@Injectable()
export class MistralOcrProvider extends OcrProvider {
  readonly nome = 'mistral';
  private readonly modelo: string;

  constructor(
    private readonly cliente: MistralClient,
    config: ConfigService,
  ) {
    super();
    this.modelo = config.get<string>('MISTRAL_OCR_MODEL') || 'mistral-ocr-latest';
  }

  async extrairTexto(pdf: Buffer): Promise<PaginaTexto[]> {
    const resposta = await this.cliente.post<RespostaOcr>(
      '/ocr',
      {
        model: this.modelo,
        document: {
          type: 'document_url',
          document_url: `data:application/pdf;base64,${pdf.toString('base64')}`,
        },
        include_image_base64: false,
      },
      180_000,
    );

    return [...(resposta.pages ?? [])]
      .sort((a, b) => a.index - b.index)
      .map((pagina, posicao) => ({ numero: posicao + 1, texto: pagina.markdown ?? '' }));
  }
}
