import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Response, Request } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException
        ? exception.getResponse()
        : { message: 'Internal server error' };

    const normalized = this.normalizeExceptionResponse(exceptionResponse);

    response.status(status).json({
      success: false,
      statusCode: status,
      path: request.url,
      method: request.method,
      timestamp: new Date().toISOString(),
      error: normalized,
    });
  }

  private normalizeExceptionResponse(exceptionResponse: string | object): {
    code: string;
    message: string | string[];
    details?: unknown;
  } {
    if (typeof exceptionResponse === 'string') {
      return {
        code: 'HTTP_EXCEPTION',
        message: exceptionResponse,
      };
    }

    const responseObject = exceptionResponse as {
      error?: string;
      message?: string | string[];
      details?: unknown;
    };

    return {
      code: responseObject.error ?? 'HTTP_EXCEPTION',
      message: responseObject.message ?? 'Unexpected error',
      details: responseObject.details,
    };
  }
}
