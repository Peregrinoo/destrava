import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { LlmProvider, OcrProvider } from './ia/ia.types';

@ApiTags('saúde')
@Controller('saude')
export class SaudeController {
  constructor(
    private readonly ocr: OcrProvider,
    private readonly llm: LlmProvider,
  ) {}

  @Get()
  verificar() {
    return { status: 'ok', ocr: this.ocr.nome, llm: this.llm.nome, horario: new Date().toISOString() };
  }
}
