import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, stringToBytes } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { prodDeployer } = await getNamedAccounts();

  await deploy('GalxeBadgeReceiverV2', {
    from: prodDeployer,
    args: [],
    log: true,
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [prodDeployer],
        },
      },
    },
    deterministicDeployment: keccak256(stringToBytes('GalxeBadgeReceiverV2_Prod')),
  });

  await execute('GalxeBadgeReceiverV2', { from: prodDeployer, log: true }, 'updateDstValidity', 20736, true);

  await execute(
    'GalxeBadgeReceiverV2',
    { from: prodDeployer, log: true },
    'updateValidNftAddr',
    '0x9F471abCddc810E561873b35b8aad7d78e21a48e',
    true,
  );

  await execute(
    'GalxeBadgeReceiverV2',
    { from: prodDeployer, log: true },
    'updateValidNftAddr',
    '0xADc466855ebe8d1402C5F7e6706Fccc3AEdB44a0',
    true,
  );
};

func.tags = ['GalxeBadgeReceiverV2'];

export default func;
