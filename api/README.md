# Destrava API

API em NestJS que recebe editais (PDF ou link), lê o documento com OCR, usa um
LLM para extrair o que importa e confere cada informação no texto original.

## Rodando

```bash
cd api
cp .env.example .env   # coloque sua MISTRAL_API_KEY
npm install
npm run start:dev
```

- API: http://localhost:3000
- Documentação (Swagger): http://localhost:3000/docs

## Endpoints

| Método | Rota            | O que faz                                              |
| ------ | --------------- | ------------------------------------------------------ |
| GET    | `/saude`        | Verifica se a API está no ar e quais provedores usa    |
| GET    | `/editais`      | Lista os editais                                       |
| GET    | `/editais/:id`  | Busca um edital (`PROCESSING`, `READY` ou `FAILED`)    |
| POST   | `/editais`      | Envia um PDF (`arquivo`, multipart) ou um `url` (JSON) |

## Como um edital é destravado

```
PDF ─▶ OcrProvider ─▶ texto por página ─▶ LlmProvider ─▶ JSON ─▶ normalização ─▶ conferência das fontes
```

1. **Recebimento:** valida o PDF (assinatura e até 20 MB) e evita duplicatas pelo hash SHA-256.
2. **OCR:** extrai o texto de cada página (funciona com PDF escaneado).
3. **Extração:** o LLM preenche um JSON Schema com resumo, prazos, alertas e
   seções dinâmicas, citando o trecho literal e a página de cada informação.
4. **Normalização:** corrige ou descarta o que vier fora do contrato (datas,
   links, ícones, tipos), sem confiar cegamente no modelo.
5. **Conferência das fontes:** procura cada trecho citado no texto do OCR,
   ignorando acentos, maiúsculas e markdown. Se acha, marca `verificada: true`
   e corrige a página; se não acha, marca `verificada: false` e o app avisa.

O processamento roda em segundo plano, com limite de editais simultâneos.

## Provedores de IA

O domínio só conhece dois contratos, em `src/ia/ia.types.ts`:

- `OcrProvider.extrairTexto(pdf)` → páginas com texto
- `LlmProvider.gerarJson({ instrucoes, entrada, schema })` → objeto JSON

A implementação é escolhida pelo `.env` (`OCR_PROVIDER`, `LLM_PROVIDER`). Para
adicionar outro fornecedor, crie a classe em `src/ia/<fornecedor>/` e registre
em `src/ia/ia.module.ts`.

Hoje existe a implementação **Mistral**, chamando a API HTTP direto (sem SDK):

| Variável            | Padrão                 | Uso                                |
| ------------------- | ---------------------- | ---------------------------------- |
| `MISTRAL_API_KEY`   | —                      | Chave da API                       |
| `MISTRAL_OCR_MODEL` | `mistral-ocr-latest`   | OCR do PDF                         |
| `MISTRAL_LLM_MODEL` | `mistral-small-latest` | Extração estruturada (JSON Schema) |
| `MISTRAL_BASE_URL`  | `https://api.mistral.ai/v1` | Útil para testes              |

Para gastar ainda menos, troque o LLM por `ministral-8b-latest`.

## Próximos passos

1. Prisma + PostgreSQL para persistir os editais.
2. Trocar a fila em memória por BullMQ + Redis.
