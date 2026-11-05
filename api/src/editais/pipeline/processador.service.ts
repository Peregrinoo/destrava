import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { LlmProvider, OcrProvider, PaginaTexto } from '../../ia/ia.types';
import { ConteudoEdital } from '../edital.types';
import { instrucoesExtracao, SCHEMA_EDITAL } from './extracao.schema';
import { normalizarConteudo } from './normalizacao';
import { verificarFontes } from './verificacao-fontes';

export class ErroProcessamento extends Error {}

@Injectable()
export class ProcessadorEditais {
  private readonly maxCaracteres: number;

  constructor(
    private readonly ocr: OcrProvider,
    private readonly llm: LlmProvider,
    config: ConfigService,
  ) {
    this.maxCaracteres = Number(config.get('MAX_CARACTERES_ENTRADA') ?? 200_000);
  }

  async processar(pdf: Buffer, nomeArquivo: string | null): Promise<ConteudoEdital> {
    const paginas = (await this.ocr.extrairTexto(pdf)).filter((pagina) => pagina.texto.trim());
    if (paginas.length === 0) {
      throw new ErroProcessamento('Não encontramos texto neste PDF.');
    }

    const hoje = new Intl.DateTimeFormat('pt-BR', { dateStyle: 'full', timeZone: 'America/Fortaleza' }).format(new Date());
    const bruto = await this.llm.gerarJson({
      instrucoes: instrucoesExtracao(hoje),
      entrada: this.montarEntrada(paginas),
      nomeSchema: 'edital',
      schema: SCHEMA_EDITAL,
    });

    const conteudo = normalizarConteudo(bruto, nomeArquivo);
    if (!conteudo.resumo_simples && conteudo.secoes.length === 0) {
      throw new ErroProcessamento('Não conseguimos entender este documento.');
    }
    return verificarFontes(conteudo, paginas);
  }

  private montarEntrada(paginas: PaginaTexto[]): string {
    const partes: string[] = [];
    let total = 0;
    for (const pagina of paginas) {
      const parte = `[PÁGINA ${pagina.numero}]\n${pagina.texto.trim()}\n`;
      if (total + parte.length > this.maxCaracteres) {
        if (partes.length === 0) partes.push(parte.slice(0, this.maxCaracteres));
        break;
      }
      partes.push(parte);
      total += parte.length;
    }
    return partes.join('\n');
  }
}
