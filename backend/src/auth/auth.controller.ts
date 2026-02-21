import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import {
  ApiBody,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { LoginDto } from './dto/login.dto';
import { AuthService } from './auth.service';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate user and return JWT token' })
  @ApiBody({ type: LoginDto })
  @ApiOkResponse({
    description: 'Authentication successful',
    schema: {
      example: {
        accessToken: '<jwt>',
        tokenType: 'Bearer',
        expiresIn: '1d',
        user: {
          id: 'clx123...',
          email: 'admin@school.local',
          firstName: 'System',
          lastName: 'Admin',
          roleCodes: ['super_admin'],
          permissionCodes: ['users.read', 'users.create'],
        },
      },
    },
  })
  @ApiUnauthorizedResponse({ description: 'Invalid credentials' })
  login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }
}
