import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { compare } from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async login(loginDto: LoginDto): Promise<{
    accessToken: string;
    tokenType: string;
    expiresIn: string;
    user: {
      id: string;
      email: string;
      firstName: string;
      lastName: string;
      roleCodes: string[];
      permissionCodes: string[];
    };
  }> {
    const user = await this.prisma.user.findFirst({
      where: {
        email: loginDto.email,
        deletedAt: null,
      },
      include: {
        userRoles: {
          where: {
            deletedAt: null,
          },
          include: {
            role: {
              include: {
                rolePermissions: {
                  where: {
                    deletedAt: null,
                  },
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordMatches = await compare(loginDto.password, user.passwordHash);

    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const { roleCodes, permissionCodes } = this.extractSecurityGrants(
      user.userRoles,
    );

    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        lastLoginAt: new Date(),
      },
    });

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: process.env.JWT_EXPIRES_IN ?? '1d',
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        roleCodes,
        permissionCodes,
      },
    };
  }

  private extractSecurityGrants(
    userRoles: Array<{
      role: {
        code: string;
        isActive: boolean;
        deletedAt: Date | null;
        rolePermissions: Array<{
          permission: {
            code: string;
            deletedAt: Date | null;
          };
        }>;
      };
    }>,
  ): { roleCodes: string[]; permissionCodes: string[] } {
    const roleCodes: string[] = [];
    const permissionCodes = new Set<string>();

    for (const userRole of userRoles) {
      if (!userRole.role.isActive || userRole.role.deletedAt) {
        continue;
      }

      roleCodes.push(userRole.role.code);

      for (const rolePermission of userRole.role.rolePermissions) {
        if (!rolePermission.permission.deletedAt) {
          permissionCodes.add(rolePermission.permission.code);
        }
      }
    }

    return {
      roleCodes,
      permissionCodes: [...permissionCodes],
    };
  }
}
