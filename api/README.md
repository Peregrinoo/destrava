# Destrava API

API em NestJS que recebe editais (PDF ou link) e devolve as informações
estruturadas que o app iOS exibe, cada uma com o trecho do PDF de onde saiu.

> Estado atual: a API recebe o PDF (enviado ou baixado do link), valida o
> arquivo e evita duplicatas pelo hash SHA-256. Os editais ficam em memória e
> permanecem em `PROCESSING` até o pipeline de IA ser ligado.

## Rodando

```bash
cd api
cp .env.example .env
npm install
npm run start:dev
```

- API: http://localhost:3000
- Documentação (Swagger): http://localhost:3000/docs

## Endpoints

| Método | Rota            | O que faz                                              |
| ------ | --------------- | ------------------------------------------------------ |
| GET    | `/saude`        | Verifica se a API está no ar                           |
| GET    | `/editais`      | Lista os editais                                       |
| GET    | `/editais/:id`  | Busca um edital (`PROCESSING`, `READY` ou `FAILED`)    |
| POST   | `/editais`      | Envia um PDF (`arquivo`, multipart) ou um `url` (JSON) |

## Próximos passos

1. Prisma + PostgreSQL para persistir os editais.
2. Fila com BullMQ + Redis e um worker que extrai o texto, chama o LLM com
   saída estruturada e confere cada `fonte.trecho` no texto original.
