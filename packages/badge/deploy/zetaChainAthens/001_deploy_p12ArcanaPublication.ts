import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('oaoNFT', {
    from: deployer,
    args: [deployer, 'P12 Badge', 'P12B'],
    log: true,
  });
};

func.tags = ['oaoNFT'];

export default func;
