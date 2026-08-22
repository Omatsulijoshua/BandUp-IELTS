const axios = require('axios');
async function main() {
  console.log("Looking up IP geolocation for Supabase host via ip-api...");
  const res = await axios.get('http://ip-api.com/json/2a05:d018:837:ae00:ae23:3c1e:3f01:bd59');
  console.log(JSON.stringify(res.data, null, 2));
}
main().catch(console.error);
