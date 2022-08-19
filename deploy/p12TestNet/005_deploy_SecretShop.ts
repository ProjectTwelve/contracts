import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const weth = '0x0EE3F0848cA07E6342390C34FcC7Ea9D0217a47d';

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
