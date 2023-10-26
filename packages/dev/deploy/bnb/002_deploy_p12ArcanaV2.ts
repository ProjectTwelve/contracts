import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, parseEther, stringToBytes } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute, get } = deployments;

  const { prodDeployer } = await getNamedAccounts();

  await deploy('P12ArcanaV2', {
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
    deterministicDeployment: keccak256(stringToBytes('P12Arcana')),
  });

  if ((await get('P12ArcanaV2')).numDeployments === 1) {
    await execute('P12ArcanaV2', { from: prodDeployer, log: true }, 'setPublicationFee', parseEther('0.012'));
    await execute('P12ArcanaV2', { from: prodDeployer, log: true }, 'setProofAmount', parseEther('0.05'));
    // use MBOX for test, its decimal is 18
    // https://bscscan.com/address/0x3203c9e46ca618c8c1ce5dc67e7e9d75f5da2377
    await execute(
      'P12ArcanaV2',
      { from: prodDeployer, log: true },
      'setPublicationTokenFee',
      '0x3203c9E46cA618C8C1cE5dC67e7e9D75f5da2377',
      parseEther('9'),
    );
  }
};

func.tags = ['P12ArcanaV2'];

export default func;
