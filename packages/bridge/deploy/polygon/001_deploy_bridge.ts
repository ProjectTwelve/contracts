import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('GalxeBadgeReceiver', {
    from: deployer,
    args: [deployer],
    log: true,
  });

  await execute('GalxeBadgeReceiver', { from: deployer, log: true }, 'updateDstValidity', 20736, true);
  await execute('GalxeBadgeReceiver', { from: deployer, log: true }, 'updateDstValidity', 248832, true);
};

func.tags = ['GalxeBadgeReceiver'];

export default func;
