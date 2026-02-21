import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import {
  ExtractJwt,
  Strategy,
  type StrategyOptionsWithoutRequest,
} from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser } from '../common/interfaces/auth-user.interface';

interface JwtPayload {
  sub: string;
  email: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly prisma: PrismaService) {
    const options: StrategyOptionsWithoutRequest = {
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        process.env.JWT_SECRET ?? 'change_me_with_very_strong_secret',
    };

    super(options);
  }

  async validate(payload: JwtPayload): Promise<AuthUser> {
    const user = await this.prisma.user.findFirst({
      where: {
        id: payload.sub,
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
      throw new UnauthorizedException('Invalid token subject');
    }

    const activeRoles = user.userRoles
      .map((item) => item.role)
      .filter((role) => role.isActive && !role.deletedAt);

    const roleCodes = activeRoles.map((role) => role.code);
    const permissionCodes = [
      ...new Set(
        activeRoles.flatMap((role) =>
          role.rolePermissions
            .filter((rolePermission) => !rolePermission.permission.deletedAt)
            .map((rolePermission) => rolePermission.permission.code),
        ),
      ),
    ];

    return {
      userId: user.id,
      email: user.email,
      roleCodes,
      permissionCodes,
    };
  }
}
