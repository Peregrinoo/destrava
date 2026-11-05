import {
  BadRequestException, Body, Controller, Get, HttpCode, Param,
  Post, UploadedFile, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CriarEditalDto } from './dto/criar-edital.dto';
import { EditaisService, TAMANHO_MAXIMO_PDF } from './editais.service';

@ApiTags('editais')
@Controller('editais')
export class EditaisController {
  constructor(private readonly editais: EditaisService) {}

  @Get()
  @ApiOperation({ summary: 'Lista os editais enviados' })
  listar() {
    return this.editais.listar();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Busca um edital. Enquanto processa, status = PROCESSING.' })
  buscar(@Param('id') id: string) {
    return this.editais.buscar(id);
  }

  @Post()
  @HttpCode(202)
  @ApiOperation({ summary: 'Envia um edital (PDF ou link) para ser destravado' })
  @ApiConsumes('multipart/form-data', 'application/json')
  @ApiBody({ type: CriarEditalDto })
  @UseInterceptors(FileInterceptor('arquivo', { limits: { fileSize: TAMANHO_MAXIMO_PDF } }))
  async criar(
    @UploadedFile() arquivo: Express.Multer.File | undefined,
    @Body() corpo: CriarEditalDto,
  ) {
    if (arquivo) {
      const nome = Buffer.from(arquivo.originalname, 'latin1').toString('utf8');
      return this.editais.receberArquivo(nome, arquivo.buffer);
    }
    if (corpo.url) return this.editais.receberLink(corpo.url);
    throw new BadRequestException('Envie um PDF no campo "arquivo" ou um "url".');
  }
}
