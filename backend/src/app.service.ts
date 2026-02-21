import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: 'ok',
      service: 'school-erp-backend',
      timestamp: new Date().toISOString(),
    };
  }
}
