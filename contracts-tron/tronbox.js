
require('dotenv').config();
module.exports = {
  networks: {
    shasta: { privateKey: process.env.PRIVATE_KEY, fullHost: "https://api.shasta.trongrid.io", network_id: "2", fee_limit: 1_000_000_000 },
    mainnet: { privateKey: process.env.PRIVATE_KEY, fullHost: "https://api.trongrid.io", network_id: "1", fee_limit: 1_000_000_000 }
  },
  solc: { optimizer: { enabled: true, runs: 200 } }
};
