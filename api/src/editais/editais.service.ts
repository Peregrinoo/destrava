import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash, randomUUID } from 'node:crypto';
import { Edital } from './edital.types';

export const TAMANHO_MAXIMO_PDF = 20 * 1024 * 1024;

interface Registro {
  edital: Edital;
  hash: string;
  pdf: Buffer;
}

@Injectable()
export class EditaisService {
  private readonly registros = new Map<string, Registro>();

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
    if (existente) return existente.edital;

    const edital: Edital = {
      id: randomUUID(),
      status: 'PROCESSING',
      nome_arquivo: nomeArquivo,
      criado_em: new Date().toISOString(),
      conteudo: null,
    };
    this.registros.set(edital.id, { edital, hash, pdf });
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
}

function nomeDoLink(url: string): string {
  try {
    const nome = decodeURIComponent(new URL(url).pathname.split('/').pop() ?? '');
    return nome || 'edital.pdf';
  } catch {
    return 'edital.pdf';
  }
}
