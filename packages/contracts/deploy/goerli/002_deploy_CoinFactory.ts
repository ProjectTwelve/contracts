import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const p12Token = await get('P12Token');
  const uniswapFactory = await get('UniswapV2Factory');
  const uniswapRouter = await get('UniswapV2Router02');

  await deploy('P12CoinFactoryUpgradeable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          // TODO: add owner args when deploy
          args: [p12Token.address, uniswapFactory.address, uniswapRouter.address, 100, ethers.utils.randomBytes(32)],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
