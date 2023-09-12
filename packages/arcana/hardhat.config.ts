import { HardhatUserConfig, task } from 'hardhat/config';

import dotenv from 'dotenv';
import * as envEnc from '@chainlink/env-enc';

import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomicfoundation/hardhat-foundry';
import '@typechain/hardhat';
import 'hardhat-preprocessor';
import 'hardhat-deploy';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import 'hardhat-contract-sizer';
import '@openzeppelin/hardhat-upgrades';
import 'solidity-docgen';
import '@tovarishfin/hardhat-yul';

import verifyDeploymentOnScan from './tasks/verify';

envEnc.config();
dotenv.config();
task('verifyDeployment', 'verify hardhat deployment on scan').setAction(verifyDeploymentOnScan);

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
const deployer = process.env.DEPLOYER || '0x0000000000000000000000000000000000000000';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.19',
        settings: {
          optimizer: {
            enabled: true,
            runs: 20000,
          },
          metadata: {
            bytecodeHash: 'none',
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
      deploy: ['deploy/hardhat'],
    },
    lineaGoerli: {
      url: 'https://rpc.goerli.linea.build',
      live: true,
      chainId: 59140,
      accounts: accounts,
      gasPrice: 'auto',
      deploy: ['deploy/lineaGoerli'],
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
      lineaGoerli: deployer,
    },
    owner: {},
  },
  paths: {
    sources: './src', // Use ./src rather than ./contracts as Hardhat expects
    cache: './cache_hardhat', // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  deterministicDeployment: {
    44010: {
      factory: '0xCB2c067Db41aB40Fe6583BE811C15FF190b05dAF',
      deployer: '',
      funding: '',
      signedTx: '',
    },
    20736: {
      factory: '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086',
      deployer: '',
      funding: '',
      signedTx: '',
    },
    248832: {
      factory: '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086',
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
  external: {},
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
      pudge: 'p12',
      butcher: 'p12',
      goerli: process.env.ETHERSCAN_API_KEY!,
      polygonMumbai: process.env.POLYSCAN_API_KEY!,
      polygon: process.env.POLYSCAN_API_KEY!,
      bsc: process.env.BSCSCAN_API_KEY!,
      lineaGoerli: process.env.LINEASCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'lineaGoerli',
        chainId: 59140,
        urls: {
          apiURL: 'https://api-testnet.lineascan.build/api',
          browserURL: 'https://goerli.lineascan.build/',
        },
      },
      {
        network: 'p12TestNet',
        chainId: 44010,
        urls: {
          apiURL: 'https://blockscout.p12.games/api',
          browserURL: 'https://blockscout.p12.games/',
        },
      },
      {
        network: 'pudge',
        chainId: 20736,
        urls: {
          apiURL: 'https://explorer.p12.games/api',
          browserURL: 'https://explorer.p12.games/',
        },
      },
      {
        network: 'butcher',
        chainId: 248832,
        urls: {
          apiURL: 'https://butcher.explorer.p12.games/api',
          browserURL: 'https://butcher.explorer.p12.games',
        },
      },
    ],
  },
};

export default config;
