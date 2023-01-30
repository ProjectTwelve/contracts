import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const p12 = await get('P12Token');

  await deploy('EqualSwap', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [p12.address, owner],
        },
      },
    },
    log: true,
  });
};
func.tags = ['EqualSwap'];
export default func;
