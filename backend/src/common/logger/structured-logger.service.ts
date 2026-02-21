import { Injectable, LoggerService } from '@nestjs/common';

@Injectable()
export class StructuredLogger implements LoggerService {
  log(message: unknown, context?: string): void {
    this.print('info', message, context);
  }

  error(message: unknown, trace?: string, context?: string): void {
    this.print('error', message, context, trace);
  }

  warn(message: unknown, context?: string): void {
    this.print('warn', message, context);
  }

  debug(message: unknown, context?: string): void {
    this.print('debug', message, context);
  }

  verbose(message: unknown, context?: string): void {
    this.print('verbose', message, context);
  }

  private print(
    level: string,
    message: unknown,
    context?: string,
    trace?: string,
  ): void {
    const payload = {
      timestamp: new Date().toISOString(),
      level,
      context,
      message: this.normalize(message),
      trace,
    };

    console.log(JSON.stringify(payload));
  }

  private normalize(message: unknown): unknown {
    if (message instanceof Error) {
      return {
        name: message.name,
        message: message.message,
      };
    }

    return message;
  }
}
