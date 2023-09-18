import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('oaoNFTWithBridge', {
    from: deployer,
    args: [deployer, 20736, 'P12 Badge', 'P12B'],
    log: true,
  });
};

func.tags = ['oaoNFTWithBridge'];

export default func;
