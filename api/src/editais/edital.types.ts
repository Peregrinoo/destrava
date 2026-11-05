export type StatusEdital = 'PROCESSING' | 'READY' | 'FAILED';

export type TipoDocumento =
  | 'selecao' | 'exame' | 'licitacao' | 'convocacao'
  | 'resultado' | 'retificacao' | 'judicial' | 'outro';

export type TipoBloco = 'lista' | 'checklist' | 'etapas' | 'valores' | 'tabela' | 'texto';

export interface Fonte {
  trecho: string;
  pagina: number | null;
  verificada: boolean | null;
}

export interface ItemSecao {
  id: string;
  texto: string;
  detalhe?: string | null;
  valor?: string | null;
  data?: string | null;
  fonte?: Fonte | null;
}

export interface Secao {
  id: string;
  pergunta: string;
  bloco: TipoBloco;
  icone?: string | null;
  itens: ItemSecao[];
}

export interface ConteudoEdital {
  documento: { titulo: string; orgao?: string | null; tipo: TipoDocumento; finalidade?: string | null };
  resumo_simples: string;
  destaques: string[];
  exige_acao: boolean;
  proximo_passo?: { acao: string; link?: string | null; prazo?: string | null } | null;
  datas: { id: string; evento: string; data?: string | null; hora?: string | null; fonte?: Fonte | null }[];
  atencao: { id: string; alerta: string; gravidade: 'alta' | 'media'; fonte?: Fonte | null }[];
  nao_informado: string[];
  contato?: { email?: string | null; site?: string | null } | null;
  secoes: Secao[];
}

export interface Edital {
  id: string;
  status: StatusEdital;
  nome_arquivo: string | null;
  criado_em: string;
  conteudo: ConteudoEdital | null;
  erro: string | null;
}
