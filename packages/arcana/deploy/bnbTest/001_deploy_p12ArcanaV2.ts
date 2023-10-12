import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

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
  });

  await execute('P12ArcanaV2', { from: deployer, log: true }, 'setPublicationFee', parseEther('0.01'));
  await execute('P12ArcanaV2', { from: deployer, log: true }, 'setProofNativeAmount', parseEther('0.01'));
  // use DAI for test, its decimal is 18
  // https://testnet.bscscan.com/address/0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867
  await execute(
    'P12ArcanaV2',
    { from: deployer, log: true },
    'setProofTokenAndAmount',
    '0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867',
    parseEther('1'),
  );
};

func.tags = ['P12ArcanaV2'];

export default func;
