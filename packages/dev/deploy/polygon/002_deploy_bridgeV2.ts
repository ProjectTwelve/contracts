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
    deterministicDeployment: keccak256(stringToBytes('GalxeBadgeReceiverV2_PROD')),
  });

  await execute('GalxeBadgeReceiverV2', { from: prodDeployer, log: true }, 'updateDstValidity', 20736, true);

  await execute(
    'GalxeBadgeReceiverV2',
    { from: prodDeployer, log: true },
    'updateValidNftAddr',
    '0xC18Eeac03F52ac67F956C3Fb7526a119475778dd',
    true,
  );

  await execute(
    'GalxeBadgeReceiverV2',
    { from: prodDeployer, log: true },
    'updateValidNftAddr',
    '0x1871464F087dB27823Cff66Aa88599AA4815aE95',
    true,
  );
};

func.tags = ['GalxeBadgeReceiverV2'];

export default func;
