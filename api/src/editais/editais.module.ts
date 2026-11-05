import { Module } from '@nestjs/common';
import { EditaisController } from './editais.controller';
import { EditaisService } from './editais.service';

@Module({
  controllers: [EditaisController],
  providers: [EditaisService],
})
export class EditaisModule {}
