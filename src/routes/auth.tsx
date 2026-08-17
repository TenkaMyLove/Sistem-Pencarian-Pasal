import { Hono } from 'hono';
import bcrypt from 'bcryptjs';
import { query } from '../db/index.js';
import { LoginView } from '../views/login.js';
import { setSession, clearSession, getSession } from '../middleware/auth.js';

export const authRoutes = new Hono();

// GET /login
authRoutes.get('/login', (c) => {
  const existingUser = getSession(c);
  if (existingUser) {
    return c.redirect('/pencarian');
  }
  return c.html(<LoginView />);
});

// POST /login
authRoutes.post('/login', async (c) => {
  const body = await c.req.parseBody();
  const username = String(body.username || '').trim();
  const kata_sandi = String(body.kata_sandi || '').trim();

  if (!username || !kata_sandi) {
    return c.html(<LoginView error="Username dan kata sandi wajib diisi" />, 400);
  }

  // Query user from DB
  const users = await query<any>(
    'SELECT id, username, kata_sandi_terenkripsi, peran FROM pengguna WHERE LOWER(username) = LOWER($1)',
    [username]
  );

  if (users.length === 0) {
    // PRD USER-4 requirement: General error message without revealing specific username/password failure
    return c.html(<LoginView error="Username atau kata sandi salah" />, 401);
  }

  const user = users[0];
  const passwordValid = await bcrypt.compare(kata_sandi, user.kata_sandi_terenkripsi);

  if (!passwordValid) {
    return c.html(<LoginView error="Username atau kata sandi salah" />, 401);
  }

  // Set Session Cookie
  setSession(c, {
    id: user.id,
    username: user.username,
    peran: user.peran,
  });

  // Redirect based on role
  if (user.peran === 'Admin') {
    return c.redirect('/kelola-akun');
  }
  return c.redirect('/pencarian');
});

// GET /logout
authRoutes.get('/logout', (c) => {
  clearSession(c);
  return c.redirect('/login');
});
