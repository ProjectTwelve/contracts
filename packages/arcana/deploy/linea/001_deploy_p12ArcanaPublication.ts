import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('P12ArcanaPublication', {
    from: deployer,
    args: [deployer],
    log: true,
  });

  await execute('P12ArcanaPublication', { from: deployer, log: true }, 'setPublicationFee', parseEther('0.0012'));
};

func.tags = ['P12ArcanaPublication'];

export default func;
