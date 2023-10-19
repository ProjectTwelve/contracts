import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, parseEther, stringToBytes } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute, get } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('P12ArcanaV2', {
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
    deterministicDeployment: keccak256(stringToBytes('P12Arcana')),
  });

  if ((await get('P12ArcanaV2')).numDeployments === 1) {
    await execute('P12ArcanaV2', { from: deployer, log: true }, 'setPublicationFee', parseEther('0.01'));
    await execute('P12ArcanaV2', { from: deployer, log: true }, 'setProofAmount', parseEther('0.01'));
    // use DAI for test, its decimal is 18
    // https://testnet.bscscan.com/address/0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867
    await execute(
      'P12ArcanaV2',
      { from: deployer, log: true },
      'setPublicationTokenFee',
      '0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867',
      parseEther('1'),
    );

    await execute(
      'P12ArcanaV2',
      { from: deployer, log: true },
      'updateSigners',
      '0x803470638940Ec595B40397cbAa597439DE55907',
      true,
    );
  }
};

func.tags = ['P12ArcanaV2'];

export default func;
