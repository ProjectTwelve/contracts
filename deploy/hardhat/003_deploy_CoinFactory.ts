import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const p12Token = await get('P12Token');
  const uniswapFactory = await get('UniswapV2Factory');
  const uniswapRouter = await get('UniswapV2Router02');

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
          args: [owner, p12Token.address, uniswapFactory.address, uniswapRouter.address, 100, ethers.utils.randomBytes(32)],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
