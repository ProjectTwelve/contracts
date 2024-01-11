import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, stringToBytes } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('GalxeBadgeReceiverV2', {
    from: deployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [deployer],
        },
      },
    },
    deterministicDeployment: keccak256(stringToBytes('GalxeBadgeReceiverV2')),
  });

  await execute('GalxeBadgeReceiverV2', { from: deployer, log: true }, 'updateDstValidity', 20736, true);
};

func.tags = ['GalxeBadgeReceiverV2'];

export default func;
