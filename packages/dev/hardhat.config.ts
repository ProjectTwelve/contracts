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
const prodDeployer = process.env.PROD_DEPLOYER || '0x0000000000000000000000000000000000000000';
const prodDeployerKey = process.env.PROD_DEPLOYER_KEY || '0x0000000000000000000000000000000000000000000000000000000000000000';

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
    polygonFork: {
      accounts: accounts,
      chainId: 137,
      url: 'https://rpc.tenderly.co/fork/10575d78-56a4-476c-8669-33b74397cc8f',
      live: true,
      deploy: ['deploy/polygon'],
    },
    polygon: {
      accounts: [prodDeployerKey],
      chainId: 137,
      gasPrice: 100000000000, // 100 gwei
      url: 'https://polygon-bor.publicnode.com',
      live: true,
      deploy: ['deploy/polygon'],
    },
    bnb: {
      accounts: [prodDeployerKey],
      chainId: 56,
      url: 'https://bsc.publicnode.com',
      live: true,
      deploy: ['deploy/bnb'],
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
    mumbai: {
      url: process.env.MUMBAI_RPC_URL || '',
      live: true,
      accounts: accounts,
      gasPrice: 'auto', //
      deploy: ['deploy/mumbai'],
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
    zetaChainAthens: {
      url: 'https://zetachain-athens-evm.blockpi.network/v1/rpc/public',
      live: true,
      chainId: 7001,
      accounts: accounts,
      gas: 'auto',
      gasPrice: 'auto', //
      tags: ['staging'],
      deploy: ['deploy/zetaChainAthens'],
    },
    lineaGoerli: {
      url: 'https://rpc.goerli.linea.build',
      live: true,
      chainId: 59140,
      accounts: accounts,
      gasPrice: 'auto',
      deploy: ['deploy/lineaGoerli'],
    },
    linea: {
      url: 'https://rpc.linea.build',
      live: true,
      chainId: 59144,
      accounts: [prodDeployerKey],
      gasPrice: 'auto',
      deploy: ['deploy/linea'],
    },
    bnbTest: {
      url: 'https://bsc-testnet.publicnode.com',
      live: true,
      chainId: 97,
      accounts: accounts,
      gasPrice: 'auto',
      deploy: ['deploy/bnbTest'],
    },
    mantaTest: {
      url: 'https://manta-testnet.calderachain.xyz/http',
      live: true,
      chainId: 3441005,
      accounts: accounts,
      gasPrice: 'auto',
      deploy: ['deploy/mantaTest'],
    },
    manta: {
      url: 'https://pacific-rpc.manta.network/http',
      live: true,
      chainId: 169,
      accounts: [prodDeployerKey],
      gasPrice: 'auto',
      deploy: ['deploy/manta'],
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
      // default address provided by hardhat
      hardhat: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      lineaGoerli: deployer,
      bnbTest: deployer,
      mumbai: deployer,
      butcher: deployer,
      polygonFork: deployer,
      zetaChainAthens: deployer,
      mantaTest: deployer,
    },
    prodDeployer: {
      linea: prodDeployer,
      bnb: prodDeployer,
      polygon: prodDeployer,
      manta: prodDeployer,
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
      polygon: process.env.POLYSCAN_API_KEY!,
      bsc: process.env.BSCSCAN_API_KEY!,
      zetaChainAthens: 'zeta',
      manta: 'manta',
      mantaTest: 'mantaTest',
      lineaGoerli: process.env.LINEASCAN_API_KEY!,
      linea: process.env.LINEASCAN_API_KEY!,
      bscTestnet: process.env.BSCSCAN_API_KEY!,
    },
    customChains: [
      {
        network: 'zetaChainAthens',
        chainId: 7001,
        urls: {
          apiURL: 'https://zetachain-athens-3.blockscout.com/api',
          browserURL: 'https://zetachain-athens-3.blockscout.com/',
        },
      },
      {
        network: 'manta',
        chainId: 169,
        urls: {
          apiURL: 'https://pacific-explorer.manta.network/api',
          browserURL: 'https://pacific-explorer.manta.network/',
        },
      },
      {
        network: 'mantaTest',
        chainId: 3441005,
        urls: {
          apiURL: 'https://pacific-explorer.testnet.manta.network/api',
          browserURL: 'https://pacific-explorer.testnet.manta.network/',
        },
      },
      {
        network: 'lineaGoerli',
        chainId: 59140,
        urls: {
          apiURL: 'https://api-testnet.lineascan.build/api',
          browserURL: 'https://goerli.lineascan.build/',
        },
      },
      {
        network: 'linea',
        chainId: 59144,
        urls: {
          apiURL: 'https://api.lineascan.build/api',
          browserURL: 'https://lineascan.build/',
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
