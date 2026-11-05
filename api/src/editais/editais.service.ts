import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'node:crypto';
import { ErroProvedorIA } from '../ia/ia.types';
import { Edital } from './edital.types';
import { ErroProcessamento, ProcessadorEditais } from './pipeline/processador.service';

export const TAMANHO_MAXIMO_PDF = 20 * 1024 * 1024;

interface Registro {
  edital: Edital;
  hash: string;
  pdf: Buffer | null;
}

@Injectable()
export class EditaisService {
  private readonly logger = new Logger(EditaisService.name);
  private readonly registros = new Map<string, Registro>();
  private readonly fila: string[] = [];
  private readonly limiteSimultaneo: number;
  private ativos = 0;

  constructor(
    private readonly processador: ProcessadorEditais,
    config: ConfigService,
  ) {
    this.limiteSimultaneo = Math.max(1, Number(config.get('MAX_PROCESSAMENTOS_SIMULTANEOS') ?? 2));
  }

  listar(): Edital[] {
    return [...this.registros.values()]
      .map((registro) => registro.edital)
      .sort((a, b) => b.criado_em.localeCompare(a.criado_em));
  }

  buscar(id: string): Edital {
    const registro = this.registros.get(id);
    if (!registro) throw new NotFoundException('Edital não encontrado.');
    return registro.edital;
  }

  receberArquivo(nomeArquivo: string, pdf: Buffer): Edital {
    if (pdf.length === 0 || !pdf.subarray(0, 5).toString('latin1').startsWith('%PDF-')) {
      throw new BadRequestException('O arquivo enviado não é um PDF válido.');
    }
    if (pdf.length > TAMANHO_MAXIMO_PDF) {
      throw new BadRequestException('O PDF passa de 20 MB.');
    }

    const hash = createHash('sha256').update(pdf).digest('hex');
    const existente = [...this.registros.values()].find((registro) => registro.hash === hash);
    if (existente && existente.edital.status !== 'FAILED') return existente.edital;

    const edital: Edital = {
      id: existente?.edital.id ?? randomUUID(),
      status: 'PROCESSING',
      nome_arquivo: nomeArquivo,
      criado_em: existente?.edital.criado_em ?? new Date().toISOString(),
      conteudo: null,
      erro: null,
    };
    this.registros.set(edital.id, { edital, hash, pdf });
    this.enfileirar(edital.id);
    return edital;
  }

  async receberLink(url: string): Promise<Edital> {
    let resposta: Response;
    try {
      resposta = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(15_000) });
    } catch {
      throw new BadRequestException('Não foi possível baixar o PDF desse link.');
    }
    if (!resposta.ok) {
      throw new BadRequestException(`O link respondeu com status ${resposta.status}.`);
    }
    if (Number(resposta.headers.get('content-length') ?? 0) > TAMANHO_MAXIMO_PDF) {
      throw new BadRequestException('O PDF passa de 20 MB.');
    }

    const pdf = Buffer.from(await resposta.arrayBuffer());
    return this.receberArquivo(nomeDoLink(resposta.url || url), pdf);
  }

  private enfileirar(id: string) {
    this.fila.push(id);
    this.proximo();
  }

  private proximo() {
    while (this.ativos < this.limiteSimultaneo && this.fila.length > 0) {
      const id = this.fila.shift()!;
      this.ativos++;
      void this.executar(id).finally(() => {
        this.ativos--;
        this.proximo();
      });
    }
  }

  private async executar(id: string) {
    const registro = this.registros.get(id);
    if (!registro?.pdf) return;
    const inicio = Date.now();

    try {
      const conteudo = await this.processador.processar(registro.pdf, registro.edital.nome_arquivo);
      registro.edital = { ...registro.edital, status: 'READY', conteudo, erro: null };
      this.logger.log(`Edital ${id} destravado em ${((Date.now() - inicio) / 1000).toFixed(1)}s.`);
    } catch (erro) {
      this.logger.error(`Edital ${id} falhou: ${(erro as Error).message}`);
      registro.edital = { ...registro.edital, status: 'FAILED', conteudo: null, erro: mensagemPublica(erro) };
    } finally {
      registro.pdf = null;
    }
  }
}

function mensagemPublica(erro: unknown): string {
  if (erro instanceof ErroProcessamento) return erro.message;
  if (erro instanceof ErroProvedorIA) return 'O serviço de leitura de documentos está indisponível. Tente de novo em instantes.';
  return 'Não conseguimos destravar este edital.';
}

function nomeDoLink(url: string): string {
  try {
    const nome = decodeURIComponent(new URL(url).pathname.split('/').pop() ?? '');
    return nome || 'edital.pdf';
  } catch {
    return 'edital.pdf';
  }
}
