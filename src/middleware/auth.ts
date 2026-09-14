import { Context, Next } from 'hono';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';

export type UserRole = 'Pengelola' | 'Perancang' | 'Admin' | 'Tamu';

export interface UserSession {
  id: number;
  username: string;
  peran: UserRole;
}

export type Env = {
  Variables: {
    user: UserSession;
  };
};

const COOKIE_NAME = 'p3h_session';

export const GUEST_USER: UserSession = {
  id: 0,
  username: 'Tamu / Publik',
  peran: 'Tamu',
};

export function createSessionToken(user: UserSession): string {
  const payload = JSON.stringify({
    id: user.id,
    username: user.username,
    peran: user.peran,
    exp: Date.now() + 24 * 60 * 60 * 1000,
  });
  return Buffer.from(payload).toString('base64');
}

export function parseSessionToken(token: string): UserSession | null {
  try {
    const jsonStr = Buffer.from(token, 'base64').toString('utf8');
    const data = JSON.parse(jsonStr);
    if (data.exp && Date.now() > data.exp) {
      return null;
    }
    return {
      id: data.id,
      username: data.username,
      peran: data.peran,
    };
  } catch (e) {
    return null;
  }
}

export function setSession(c: Context, user: UserSession) {
  const token = createSessionToken(user);
  setCookie(c, COOKIE_NAME, token, {
    httpOnly: true,
    path: '/',
    maxAge: 86400,
    sameSite: 'Lax',
  });
}

export function clearSession(c: Context) {
  deleteCookie(c, COOKIE_NAME, { path: '/' });
}

export function getSession(c: Context): UserSession | null {
  const token = getCookie(c, COOKIE_NAME);
  if (!token) return null;
  return parseSessionToken(token);
}

// Middleware: Allows logged in users or guests (auto-assigns GUEST_USER if not logged in)
export async function allowGuestOrAuth(c: Context<Env>, next: Next) {
  let user = getSession(c);
  if (!user) {
    user = GUEST_USER;
  }
  c.set('user', user);
  await next();
}

// Auth Middleware: Requires Login (any role including Tamu)
export async function requireAuth(c: Context<Env>, next: Next) {
  const user = getSession(c);
  if (!user) {
    return c.redirect('/login');
  }
  c.set('user', user);
  await next();
}

// Staff Middleware: Only Pengelola, Perancang, or Admin (Tamu is rejected/redirected)
export async function requireStaff(c: Context<Env>, next: Next) {
  const user = getSession(c);
  if (!user || user.peran === 'Tamu') {
    return c.redirect('/pencarian');
  }
  c.set('user', user);
  await next();
}

// Role Middleware: Admin Only
export async function requireAdmin(c: Context<Env>, next: Next) {
  const user = getSession(c);
  if (!user) {
    return c.redirect('/login');
  }
  if (user.peran !== 'Admin') {
    return c.html('<h3>403 Akses Ditolak: Halaman ini hanya dapat diakses oleh Admin.</h3>', 403);
  }
  c.set('user', user);
  await next();
}

// Role Middleware: Pengelola Only
export async function requirePengelola(c: Context<Env>, next: Next) {
  const user = getSession(c);
  if (!user) {
    return c.redirect('/login');
  }
  if (user.peran !== 'Pengelola' && user.peran !== 'Admin') {
    return c.html('<h3>403 Akses Ditolak: Hanya akun Pengelola yang memiliki hak akses untuk fitur ini.</h3>', 403);
  }
  c.set('user', user);
  await next();
}
