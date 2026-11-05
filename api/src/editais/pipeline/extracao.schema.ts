export const TIPOS_DOCUMENTO = [
  'selecao', 'exame', 'licitacao', 'convocacao', 'resultado', 'retificacao', 'judicial', 'outro',
] as const;

export const TIPOS_BLOCO = ['lista', 'checklist', 'etapas', 'valores', 'tabela', 'texto'] as const;

export const ICONES = [
  'person.crop.circle.badge.questionmark',
  'person.2',
  'tray.and.arrow.up',
  'doc.text',
  'checklist',
  'list.number',
  'banknote',
  'creditcard',
  'calendar',
  'clock',
  'mappin.and.ellipse',
  'building.columns',
  'graduationcap',
  'pencil.and.list.clipboard',
  'exclamationmark.triangle',
  'questionmark.circle',
] as const;

type Schema = Record<string, unknown>;

const texto: Schema = { type: 'string' };
const data: Schema = { type: 'string', description: 'Data no formato AAAA-MM-DD' };
const nulo = (schema: Schema): Schema => ({ anyOf: [schema, { type: 'null' }] });
const lista = (itens: Schema): Schema => ({ type: 'array', items: itens });
const objeto = (propriedades: Record<string, Schema>): Schema => ({
  type: 'object',
  properties: propriedades,
  required: Object.keys(propriedades),
  additionalProperties: false,
});

const fonte = nulo(
  objeto({
    trecho: { type: 'string', description: 'Cópia literal de até 200 caracteres do edital' },
    pagina: nulo({ type: 'integer' }),
  }),
);

export const SCHEMA_EDITAL: Schema = objeto({
  documento: objeto({
    titulo: texto,
    orgao: nulo(texto),
    tipo: { type: 'string', enum: [...TIPOS_DOCUMENTO] },
    finalidade: nulo(texto),
  }),
  resumo_simples: texto,
  destaques: lista(texto),
  exige_acao: { type: 'boolean' },
  proximo_passo: nulo(objeto({ acao: texto, link: nulo(texto), prazo: nulo(data) })),
  datas: lista(objeto({ evento: texto, data: nulo(data), hora: nulo(texto), fonte })),
  atencao: lista(objeto({ alerta: texto, gravidade: { type: 'string', enum: ['alta', 'media'] }, fonte })),
  nao_informado: lista(texto),
  contato: nulo(objeto({ email: nulo(texto), site: nulo(texto) })),
  secoes: lista(
    objeto({
      pergunta: texto,
      bloco: { type: 'string', enum: [...TIPOS_BLOCO] },
      icone: { type: 'string', enum: [...ICONES] },
      itens: lista(
        objeto({
          texto,
          detalhe: nulo(texto),
          valor: nulo(texto),
          data: nulo(data),
          fonte,
        }),
      ),
    }),
  ),
});

export function instrucoesExtracao(hoje: string): string {
  return `Você traduz editais e documentos oficiais brasileiros para pessoas comuns.
Hoje é ${hoje}. O documento vem marcado por página como [PÁGINA N].

Preencha o JSON pedido seguindo estas regras:
1. Escreva em português simples, falando com "você", como para alguém do ensino médio.
2. Nunca invente. Se algo não estiver no documento, use null. Se for algo que uma pessoa esperaria saber e o documento não diz, liste em "nao_informado".
3. Todo "fonte.trecho" deve ser uma cópia LITERAL de até 200 caracteres do documento, e "fonte.pagina" o número da página onde ele está.
4. Datas sempre como AAAA-MM-DD. Horas como HH:MM.
5. "tipo" diz o que o documento é. Documentos que só informam (resultado, homologação, aviso) têm "exige_acao" = false e "proximo_passo" = null.
6. "destaques": de 2 a 4 frases curtas com o que alguém ocupado precisa saber em 10 segundos.
7. "proximo_passo": a primeira ação concreta que a pessoa deve tomar, com o prazo dela.
8. "atencao": regras que podem eliminar ou prejudicar a pessoa (impedimentos, presença obrigatória, acúmulo de bolsas, documentos difíceis, prazos curtos). Use "alta" para o que elimina.
9. "secoes": de 3 a 6 seções. Cada uma responde a UMA pergunta que a pessoa faria ao ler este documento, escrita como ela perguntaria (ex.: "Posso participar?", "O que preciso enviar?", "Quanto custa?").
10. Escolha o "bloco" que melhor mostra a resposta: "checklist" para coisas que a pessoa precisa providenciar, "etapas" para processos em ordem, "valores" para números (valor no campo "valor" e o significado em "texto"), "lista" para o resto.
11. Não repita nas seções o que já está em "datas" e "atencao".`;
}
