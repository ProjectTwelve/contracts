import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('GalxeBadgeReceiver', {
    from: deployer,
    args: ['0xC18Eeac03F52ac67F956C3Fb7526a119475778dd', deployer],
    log: true,
  });
};

func.tags = ['GalxeBadgeReceiver'];

export default func;
