import { Module } from '@nestjs/common';
import { IaModule } from '../ia/ia.module';
import { EditaisController } from './editais.controller';
import { EditaisService } from './editais.service';
import { ProcessadorEditais } from './pipeline/processador.service';

@Module({
  imports: [IaModule],
  controllers: [EditaisController],
  providers: [EditaisService, ProcessadorEditais],
})
export class EditaisModule {}
