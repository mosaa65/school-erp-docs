import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { StructuredLogger } from './common/logger/structured-logger.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });

  const logger = new StructuredLogger();
  app.useLogger(logger);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  app.useGlobalFilters(new HttpExceptionFilter());

  const swaggerConfig = new DocumentBuilder()
    .setTitle('School ERP Backend API')
    .setDescription(
      'System 01 (Shared Infrastructure) + System 02 (Academic Core: years, terms, grade levels, sections, subjects)',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
      'bearer',
    )
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  const configService = app.get(ConfigService);
  const swaggerPath = (
    configService.get<string>('SWAGGER_PATH') ?? 'api/docs'
  ).replace(/^\/+/, '');
  SwaggerModule.setup(swaggerPath, app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      docExpansion: 'none',
    },
  });

  const port = configService.get<number>('PORT') ?? 3000;
  await app.listen(port);

  logger.log(`API is running on http://localhost:${port}`);
  logger.log(
    `Swagger docs available at http://localhost:${port}/${swaggerPath}`,
  );
}

void bootstrap();
