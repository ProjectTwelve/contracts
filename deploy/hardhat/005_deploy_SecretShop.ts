import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const weth = await get('WETH9');

  await deploy('ERC721Delegate', {
    from: deployer,
    args: [owner],
    log: true,
  });

  await deploy('ERC1155Delegate', {
    from: deployer,
    args: [owner],
    log: true,
  });

  await deploy('SecretShopUpgradable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [owner, 10 ** 5, weth.address],
        },
      },
    },
    log: true,
  });
};
func.tags = ['SecretShop'];

export default func;
