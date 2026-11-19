import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const connectionUri = process.env.MYSQL_URL || process.env.DATABASE_URL || process.env.DB_URL;

export const pool = connectionUri
  ? mysql.createPool(connectionUri)
  : mysql.createPool({
      host: process.env.MYSQL_HOST || process.env.MYSQLHOST || process.env.DB_HOST || 'mysql.railway.internal',
      port: parseInt(process.env.MYSQL_PORT || process.env.MYSQLPORT || process.env.DB_PORT || '3306', 10),
      database: process.env.MYSQL_DATABASE || process.env.MYSQLDATABASE || process.env.DB_DATABASE || 'railway',
      user: process.env.MYSQL_USER || process.env.MYSQLUSER || process.env.DB_USERNAME || 'root',
      password: process.env.MYSQL_PASSWORD || process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || 'NUzQRRFlTUjARzfldNlascVkWETCbbKu',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      timezone: '+00:00',
    });

export async function query<T = any>(text: string, params?: any[]): Promise<T[]> {
  const [rows] = await pool.execute(text, params ?? []);
  return rows as T[];
}
