import { PaginaTexto } from '../../ia/ia.types';
import { ConteudoEdital, Fonte } from '../edital.types';

const TAMANHO_SHINGLE = 3;
const COBERTURA_MINIMA = 0.8;

function normalizar(texto: string): string {
  return texto
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/-\s*\n\s*/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

function shingles(palavras: string[]): Set<string> {
  const conjunto = new Set<string>();
  for (let i = 0; i + TAMANHO_SHINGLE <= palavras.length; i++) {
    conjunto.add(palavras.slice(i, i + TAMANHO_SHINGLE).join(' '));
  }
  return conjunto;
}

interface PaginaNormalizada {
  numero: number;
  texto: string;
  shingles: Set<string>;
}

export function verificarFontes(conteudo: ConteudoEdital, paginas: PaginaTexto[]): ConteudoEdital {
  const normalizadas: PaginaNormalizada[] = paginas.map((pagina) => {
    const textoNormalizado = normalizar(pagina.texto);
    return { numero: pagina.numero, texto: textoNormalizado, shingles: shingles(textoNormalizado.split(' ')) };
  });

  const verificar = (fonte: Fonte | null | undefined): Fonte | null => {
    if (!fonte) return null;
    const alvo = normalizar(fonte.trecho);
    const palavras = alvo.split(' ').filter(Boolean);
    const ordem = [...normalizadas].sort(
      (a, b) => Number(b.numero === fonte.pagina) - Number(a.numero === fonte.pagina),
    );

    const exata = alvo ? ordem.find((pagina) => pagina.texto.includes(alvo)) : undefined;
    if (exata) return { ...fonte, pagina: exata.numero, verificada: true };

    if (palavras.length > TAMANHO_SHINGLE) {
      const alvoShingles = [...shingles(palavras)];
      let melhor: { numero: number; cobertura: number } | null = null;
      for (const pagina of ordem) {
        const cobertura = alvoShingles.filter((s) => pagina.shingles.has(s)).length / alvoShingles.length;
        if (!melhor || cobertura > melhor.cobertura) melhor = { numero: pagina.numero, cobertura };
      }
      if (melhor && melhor.cobertura >= COBERTURA_MINIMA) {
        return { ...fonte, pagina: melhor.numero, verificada: true };
      }
    }

    const paginaExiste = normalizadas.some((pagina) => pagina.numero === fonte.pagina);
    return { ...fonte, pagina: paginaExiste ? fonte.pagina : null, verificada: false };
  };

  return {
    ...conteudo,
    datas: conteudo.datas.map((item) => ({ ...item, fonte: verificar(item.fonte) })),
    atencao: conteudo.atencao.map((item) => ({ ...item, fonte: verificar(item.fonte) })),
    secoes: conteudo.secoes.map((secao) => ({
      ...secao,
      itens: secao.itens.map((item) => ({ ...item, fonte: verificar(item.fonte) })),
    })),
  };
}
