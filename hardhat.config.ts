import * as dotenv from 'dotenv';

import { HardhatUserConfig, task } from 'hardhat/config';
import { addFlatTask } from './flat';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-deploy';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import '@openzeppelin/hardhat-upgrades';

dotenv.config();
addFlatTask();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const accounts = process.env.ACCOUNTS ? process.env.ACCOUNTS.split(',') : [];
const addresses = process.env.ADDESSSES ? process.env.ADDESSSES.split(',') : [];

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.15',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: 'https://testnet.p12.games/',
        blockNumber: 1229515,
      },
      // The fork configuration can be turned on or off by itself according to the situation
      chainId: 44102,
    },
    p12TestNet: {
      url: 'https://testnet.p12.games/',
      live: true,
      chainId: 44010,
      accounts: accounts,
      gas: 'auto',
      gasPrice: 3000000000,
      // tags: ['test'],
      deploy: ['deploy/p12TestNet'],
    },
    forkP12TestNet: {
      url: 'http://127.0.0.1:8545/',
    },
    rinkeby: {
      url: process.env.RINKEBY_URL || '',
      live: true,
      chainId: 4,
      accounts: accounts,
      gas: 'auto',
      gasPrice: 3000000000, // 3 Gwei
      tags: ['staging'],
      deploy: ['deploy/rinkeby'],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  namedAccounts: {
    deployer: {
      default: 0,
      p12TestNet: addresses[0],
    },
  },

  external: {
    contracts: [
      { artifacts: 'node_modules/@uniswap/v2-core/build/' },
      { artifacts: 'node_modules/@uniswap/v2-periphery/build/' },
      { artifacts: 'node_modules/canonical-weth/build/contracts/' },
      {
        artifacts: 'node_modules/@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol/',
      },
    ],
  },
};

export default config;
