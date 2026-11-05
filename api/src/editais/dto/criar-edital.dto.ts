import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsUrl } from 'class-validator';

export class CriarEditalDto {
  @ApiPropertyOptional({ description: 'Link direto para o PDF do edital', example: 'https://exemplo.gov.br/edital.pdf' })
  @IsOptional()
  @IsUrl({ protocols: ['http', 'https'], require_protocol: true }, { message: 'Informe um link válido, começando com http ou https.' })
  url?: string;

  @ApiPropertyOptional({ type: 'string', format: 'binary', description: 'Arquivo PDF do edital' })
  arquivo?: unknown;
}
