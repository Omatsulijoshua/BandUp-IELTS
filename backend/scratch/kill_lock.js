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
  console.log("Locating and killing any connections holding Prisma advisory locks...");
  
  // Terminate any connection holding the migration lock 72707369
  const killed = await prisma.$queryRawUnsafe(`
    SELECT pg_terminate_backend(PSA.pid) 
    FROM pg_locks AS PL 
    INNER JOIN pg_stat_activity AS PSA ON PSA.pid = PL.pid 
    WHERE PL.objid IN (72707369);
  `);
  
  console.log("Killed active locks result:", killed);
  console.log("Stuck migration lock cleaned successfully!");
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
  });
