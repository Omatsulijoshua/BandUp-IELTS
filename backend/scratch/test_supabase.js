const { PrismaClient } = require('@prisma/client');
const supabaseUrl = "postgresql://postgres:up43RDKHtk8WLUL3@db.gviiynntpkvzgqysnrrx.supabase.co:5432/postgres?sslmode=require";
const client = new PrismaClient({
  datasources: {
    db: {
      url: supabaseUrl,
    },
  },
});
async function main() {
  console.log("Connecting to Supabase via Direct URL...");
  const count = await client.user.count();
  console.log(`Connection successful! Total users in Supabase: ${count}`);
}
main().catch(console.error).finally(() => client.$disconnect());
