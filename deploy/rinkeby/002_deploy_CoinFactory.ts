import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const p12Token = await get('P12Token');
  const uniswapFactory = '0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f';
  const uniswapRouter = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';

  // Be carefully: Check whether proxy contract is initialized successfully
  await deploy('P12CoinFactoryUpgradeable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [p12Token.address, uniswapFactory, uniswapRouter, 86400, ethers.utils.randomBytes(32)],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
