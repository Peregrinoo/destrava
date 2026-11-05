import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EditaisModule } from './editais/editais.module';
import { SaudeController } from './saude.controller';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), EditaisModule],
  controllers: [SaudeController],
})
export class AppModule {}
