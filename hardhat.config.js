/* global ethers task */
require('@nomicfoundation/hardhat-toolbox');
const { RPC_PROVIDER, ADMIN_PRIVATE_KEY } = process.env;

module.exports = {
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: RPC_PROVIDER,
        accounts: [ADMIN_PRIVATE_KEY],
      },
    },

    sepolia: {
      url: RPC_PROVIDER,
      accounts: [ADMIN_PRIVATE_KEY],
    },
    mainnet: {
      url: RPC_PROVIDER,
      accounts: [ADMIN_PRIVATE_KEY],
    },
  },
  mocha: {
    timeout: 90000, // timeout in milliseconds
  },
  solidity: {
    version: '0.8.24',
    settings: {
      evmVersion: 'cancun',
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
};
