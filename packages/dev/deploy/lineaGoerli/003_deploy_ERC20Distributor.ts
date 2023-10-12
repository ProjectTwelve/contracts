import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('ERC20Distributor', {
    from: deployer,
    // self deployed USDT
    // https://goerli.lineascan.build/address/0x7757f3b0d9270bea2f28366a97cdec36a2de3459
    args: [deployer, '0x7757f3b0d9270bea2f28366a97cdec36a2de3459'],
    log: true,
  });

  await execute(
    'ERC20Distributor',
    { from: deployer, log: true },
    'setMerkleRoot',
    '0x4e44c703b05c0c2ce3b972025c00d18cf2c12551731df70081c89c40cc036481',
  );

  await execute('ERC20Distributor', { from: deployer, log: true }, 'setClaimPeriodEnds', 1698681600);
};

func.tags = ['ERC20Distributor'];

export default func;
