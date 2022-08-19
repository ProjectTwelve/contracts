import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const weth = '0xc778417e063141139fce010982780140aa0cd5ab';

  await deploy('ERC721Delegate', {
    from: deployer,
    log: true,
  });

  await deploy('ERC1155Delegate', {
    from: deployer,
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
          args: [10 ** 5, weth],
        },
      },
    },
    log: true,
  });
};
func.tags = ['SecretShop'];

export default func;
