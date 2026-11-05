# Destrava API

API em NestJS que recebe editais (PDF ou link), lê o documento com OCR, usa um
LLM para extrair o que importa e confere cada informação no texto original.

## Rodando

```bash
cd api
cp .env.example .env   # escolha os provedores e coloque as chaves
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

O domínio não conhece nenhum fornecedor. Ele depende só de dois contratos, em
`src/ia/ia.types.ts`:

```ts
abstract class OcrProvider {
  abstract readonly nome: string;
  abstract extrairTexto(pdf: Buffer): Promise<PaginaTexto[]>;
}

abstract class LlmProvider {
  abstract readonly nome: string;
  abstract gerarJson(pedido: PedidoJson): Promise<unknown>;
}
```

O fornecedor de cada um é escolhido no `.env`, de forma independente: dá para
usar o OCR de um e o LLM de outro.

| Variável       | Obrigatória | O que escolhe                     |
| -------------- | ----------- | --------------------------------- |
| `OCR_PROVIDER` | sim         | Quem extrai o texto do PDF        |
| `LLM_PROVIDER` | sim         | Quem transforma o texto em JSON   |

Se a variável faltar ou citar um fornecedor desconhecido, a API não sobe e
lista as opções disponíveis. Só o provedor escolhido é instanciado.

### Plugando outro fornecedor

1. Crie a classe em `src/ia/<fornecedor>/`, estendendo o contrato:

   ```ts
   @Injectable()
   export class OpenAiLlmProvider extends LlmProvider {
     readonly nome = 'openai';

     constructor(config: ConfigService) {
       super();
     }

     async gerarJson(pedido: PedidoJson): Promise<unknown> {
     }
   }
   ```

2. Registre em `src/ia/provedores.ts`:

   ```ts
   export const PROVEDORES_LLM = {
     mistral: MistralLlmProvider,
     openai: OpenAiLlmProvider,
   };
   ```

3. No `.env`, use `LLM_PROVIDER=openai` e as variáveis que a sua classe ler.

Erros do fornecedor devem ser lançados como `ErroProvedorIA`, para o app
receber uma mensagem amigável.

### Fornecedores disponíveis

**Mistral** (`mistral`), via API HTTP, sem SDK:

| Variável            | Padrão                      |
| ------------------- | --------------------------- |
| `MISTRAL_API_KEY`   | —                           |
| `MISTRAL_OCR_MODEL` | `mistral-ocr-latest`        |
| `MISTRAL_LLM_MODEL` | `mistral-small-latest`      |
| `MISTRAL_BASE_URL`  | `https://api.mistral.ai/v1` |

## Próximos passos

1. Prisma + PostgreSQL para persistir os editais.
2. Trocar a fila em memória por BullMQ + Redis.
