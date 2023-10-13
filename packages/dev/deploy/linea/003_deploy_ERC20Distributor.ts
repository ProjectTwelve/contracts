import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { prodDeployer } = await getNamedAccounts();

  await deploy('ERC20Distributor', {
    from: prodDeployer,
    // USDC on linea
    // https://lineascan.build/address/0x176211869ca2b568f2a7d4ee941e073a821ee1ff
    args: [prodDeployer, '0x176211869ca2b568f2a7d4ee941e073a821ee1ff'],
    log: true,
  });

  await execute(
    'ERC20Distributor',
    { from: prodDeployer, log: true },
    'setMerkleRoot',
    '0x12cd0132016024cd4f350d9aabb515293431327ad6e5e1dcd7064ccc6a4e6d3c',
  );

  await execute('ERC20Distributor', { from: prodDeployer, log: true }, 'setClaimPeriodEnds', 1698681600);
};

func.tags = ['ERC20Distributor'];

export default func;
