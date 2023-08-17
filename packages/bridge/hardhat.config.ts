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
const addresses = process.env.ADDESSSES ? process.env.ADDESSSES.split(',') : [];
const deployer = process.env.DEPLOYER || '0x0000000000000000000000000000000000000000';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.19',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
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
    polygonFork: {
      accounts: accounts,
      chainId: 1377777777,
      url: 'https://rpc.vnet.tenderly.co/devnet/badge-bridge-test-polygon/197d1f10-e6f9-4e73-ab8b-b067de7181b1',
      live: true,
      deploy: ['deploy/polygon'],
    },
    pudge: {
      url: 'https://rpc-chain.p12.games',
      live: true,
      chainId: 20736,
      accounts: accounts,
      gasPrice: 'auto', //
      deploy: ['deploy/pudge'],
    },
    butcher: {
      url: 'https://butcher.rpc.p12.games',
      live: true,
      chainId: 248832,
      accounts: accounts,
      gasPrice: 1500000000, // 1.5 gwei
      deploy: ['deploy/butcher'],
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
      pudge: addresses[0],
      mumbai: deployer,
      butcher: deployer,
      polygonFork: deployer,
    },
    owner: {
      pudge: addresses[0],
    },
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
  external: {
    contracts: [
      {
        artifacts: 'node_modules/@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/',
      },
      {
        artifacts: 'node_modules/@uniswap/v3-periphery/artifacts/contracts/libraries/NFTDescriptor.sol/',
      },
      { artifacts: 'node_modules/@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol' },
      {
        artifacts: 'node_modules/canonical-weth/build/contracts/',
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
      pudge: 'p12',
      butcher: 'p12',
      goerli: process.env.ETHERSCAN_API_KEY!,
      polygonMumbai: process.env.POLYSCAN_API_KEY!,
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
