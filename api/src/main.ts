import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const config = new DocumentBuilder()
    .setTitle('Destrava API')
    .setDescription('Recebe editais em PDF e devolve as informações estruturadas, com a fonte de cada uma.')
    .setVersion('0.1.0')
    .build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, config));

  const porta = Number(process.env.PORT ?? 3000);
  await app.listen(porta);
  console.log(`Destrava API rodando em http://localhost:${porta} (docs em /docs)`);
}

bootstrap();
