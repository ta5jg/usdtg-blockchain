require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.20", settings: { optimizer: { enabled: true, runs: 200 } } },
    ],
  },
  networks: {
    bsctestnet: {
      url: process.env.BSC_TESTNET_RPC || "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    bsc: {
      url: process.env.BSC_RPC || "https://bsc-dataseed.binance.org",
      chainId: 56,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources: "./contracts",
    scripts: "./scripts",
  },
  ignoreFiles: ["contracts/_mythril/USDExchangeToken_mythril.ignore.sol"]
};