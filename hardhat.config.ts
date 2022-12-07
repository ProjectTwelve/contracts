import * as dotenv from 'dotenv';

import { HardhatUserConfig, task } from 'hardhat/config';
import { addFlatTask } from './tools/flat';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-deploy';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import 'hardhat-contract-sizer';
import '@openzeppelin/hardhat-upgrades';
import 'solidity-docgen';

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
      // forking: {
      //   url: 'https://testnet.p12.games/',
      //   blockNumber: 997788,
      // },
      // The fork configuration can be turned on or off by itself according to the situation
      chainId: 44102,
      deploy: ['deploy/hardhat'],
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
    p12Chain: {
      url: 'https://rpc-chain.p12.games',
      live: true,
      chainId: 20736,
      accounts: accounts,
      gasPrice: 1000000000,
      deploy: ['deploy/p12Chain'],
    },
    goerli: {
      url: process.env.GOERLI_URL || '',
      live: true,
      chainId: 5,
      accounts: accounts,
      gas: 'auto',
      gasPrice: 'auto', //
      tags: ['staging'],
      deploy: ['deploy/goerli'],
    },
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  namedAccounts: {
    deployer: {
      default: 0,
      p12TestNet: addresses[0],
      p12Chain: addresses[0],
    },
    owner: {
      default: 0,
      p12Chain: addresses[0],
    },
  },
  deterministicDeployment: {
    44010: {
      factory: '0xCB2c067Db41aB40Fe6583BE811C15FF190b05dAF',
      deployer: '',
      funding: '',
      signedTx: '',
    },
    5: {
      factory: '0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7',
      deployer: '',
      funding: '',
      signedTx: '',
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
  docgen: {
    pages: 'files',
    exclude: ['tests'],
    templates: 'theme/markdown',
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      p12TestNet: 'p12',
      p12Chain: 'p12',
      rinkeby: process.env.ETHERSCAN_API_KEY!,
      goerli: process.env.ETHERSCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'p12TestNet',
        chainId: 44010,
        urls: {
          apiURL: 'https://blockscout.p12.games/api',
          browserURL: 'https://blockscout.p12.games/',
        },
      },
      {
        network: 'p12Chain',
        chainId: 20736,
        urls: {
          apiURL: 'https://explorer.p12.games/api',
          browserURL: 'https://explorer.p12.games/',
        },
      },
    ],
  },
};

export default config;
