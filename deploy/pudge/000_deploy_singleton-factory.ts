import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('deterministic-deployment-proxy', {
    from: deployer,
    log: true,
  });
};

func.tags = ['Singleton'];
export default func;
