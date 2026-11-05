import { ConteudoEdital, Fonte, ItemSecao, Secao, TipoBloco, TipoDocumento } from '../edital.types';
import { ICONES, TIPOS_BLOCO, TIPOS_DOCUMENTO } from './extracao.schema';

type Bruto = Record<string, unknown>;

const objeto = (valor: unknown): Bruto =>
  valor && typeof valor === 'object' && !Array.isArray(valor) ? (valor as Bruto) : {};

const lista = (valor: unknown): unknown[] => (Array.isArray(valor) ? valor : []);

const texto = (valor: unknown): string | null =>
  typeof valor === 'string' && valor.trim() ? valor.trim() : null;

const data = (valor: unknown): string | null => {
  const s = texto(valor);
  return s && /^\d{4}-\d{2}-\d{2}$/.test(s) && !Number.isNaN(Date.parse(s)) ? s : null;
};

const hora = (valor: unknown): string | null => {
  const s = texto(valor);
  return s && /^\d{1,2}:\d{2}$/.test(s) ? s.padStart(5, '0') : null;
};

const link = (valor: unknown): string | null => {
  const s = texto(valor);
  if (!s) return null;
  try {
    const url = new URL(s);
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.toString() : null;
  } catch {
    return null;
  }
};

const email = (valor: unknown): string | null => {
  const s = texto(valor);
  return s && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s) ? s : null;
};

function umDe<T extends string>(valor: unknown, opcoes: readonly T[], padrao: T): T {
  return opcoes.includes(valor as T) ? (valor as T) : padrao;
}

function fonte(valor: unknown): Fonte | null {
  const bruto = objeto(valor);
  const trecho = texto(bruto.trecho);
  if (!trecho) return null;
  const pagina = typeof bruto.pagina === 'number' && Number.isInteger(bruto.pagina) && bruto.pagina > 0 ? bruto.pagina : null;
  return { trecho: trecho.slice(0, 400), pagina, verificada: null };
}

export function normalizarConteudo(entrada: unknown, nomeArquivo: string | null): ConteudoEdital {
  const bruto = objeto(entrada);
  const documento = objeto(bruto.documento);
  const tipo = umDe<TipoDocumento>(documento.tipo, TIPOS_DOCUMENTO, 'outro');

  const passo = objeto(bruto.proximo_passo);
  const acao = texto(passo.acao);
  const exigeAcao = typeof bruto.exige_acao === 'boolean' ? bruto.exige_acao : Boolean(acao);

  const contato = objeto(bruto.contato);
  const contatoEmail = email(contato.email);
  const contatoSite = link(contato.site);

  const secoes: Secao[] = lista(bruto.secoes)
    .map(objeto)
    .map((secao, i): Secao | null => {
      const pergunta = texto(secao.pergunta);
      const itens: ItemSecao[] = lista(secao.itens)
        .map(objeto)
        .map((item, j): ItemSecao | null => {
          const valorTexto = texto(item.texto);
          if (!valorTexto) return null;
          return {
            id: `s${i + 1}-i${j + 1}`,
            texto: valorTexto,
            detalhe: texto(item.detalhe),
            valor: texto(item.valor),
            data: data(item.data),
            fonte: fonte(item.fonte),
          };
        })
        .filter((item): item is ItemSecao => item !== null);
      if (!pergunta || itens.length === 0) return null;
      return {
        pergunta,
        bloco: umDe<TipoBloco>(secao.bloco, TIPOS_BLOCO, 'lista'),
        icone: umDe(secao.icone, ICONES, 'doc.text'),
        itens,
      };
    })
    .filter((secao): secao is Secao => secao !== null)
    .slice(0, 7);

  return {
    documento: {
      titulo: texto(documento.titulo) ?? nomeArquivo?.replace(/\.pdf$/i, '') ?? 'Edital',
      orgao: texto(documento.orgao),
      tipo,
      finalidade: texto(documento.finalidade),
    },
    resumo_simples: texto(bruto.resumo_simples) ?? '',
    destaques: lista(bruto.destaques).map(texto).filter((d): d is string => d !== null).slice(0, 5),
    exige_acao: exigeAcao,
    proximo_passo: exigeAcao && acao ? { acao, link: link(passo.link), prazo: data(passo.prazo) } : null,
    datas: lista(bruto.datas)
      .map(objeto)
      .map((item) => ({ evento: texto(item.evento), data: data(item.data), hora: hora(item.hora), fonte: fonte(item.fonte) }))
      .filter((item): item is typeof item & { evento: string } => item.evento !== null)
      .sort((a, b) => (a.data ?? '9999').localeCompare(b.data ?? '9999')),
    atencao: lista(bruto.atencao)
      .map(objeto)
      .map((item) => ({
        alerta: texto(item.alerta),
        gravidade: umDe(item.gravidade, ['alta', 'media'] as const, 'media'),
        fonte: fonte(item.fonte),
      }))
      .filter((item): item is typeof item & { alerta: string } => item.alerta !== null),
    nao_informado: lista(bruto.nao_informado).map(texto).filter((n): n is string => n !== null),
    contato: contatoEmail || contatoSite ? { email: contatoEmail, site: contatoSite } : null,
    secoes,
  };
}
