const fs = require('fs');
const path = require('path');

// Manually load .env file
const dotenvPath = path.resolve(__dirname, '../.env');
if (fs.existsSync(dotenvPath)) {
  const envConfig = fs.readFileSync(dotenvPath, 'utf8');
  for (const line of envConfig.split('\n')) {
    const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
    if (match) {
      const key = match[1];
      let value = match[2] || '';
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      } else if (value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }
      process.env[key] = value.trim();
    }
  }
}

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Cleaning database schema...");
  await prisma.$executeRawUnsafe(`DROP SCHEMA public CASCADE;`);
  await prisma.$executeRawUnsafe(`CREATE SCHEMA public;`);
  console.log("Database schema successfully cleaned! Public schema is now completely empty.");
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
