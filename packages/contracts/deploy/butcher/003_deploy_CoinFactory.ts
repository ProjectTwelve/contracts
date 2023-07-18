import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const p12Token = await get('P12Token');

  const gameCoinImpl = await get('P12GameCoin');

  const posManager = await get('NonfungiblePositionManager');

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
          args: [deployer, p12Token.address, posManager.address, gameCoinImpl.address],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
