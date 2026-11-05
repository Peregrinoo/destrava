import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('saúde')
@Controller('saude')
export class SaudeController {
  @Get()
  verificar() {
    return { status: 'ok', horario: new Date().toISOString() };
  }
}
