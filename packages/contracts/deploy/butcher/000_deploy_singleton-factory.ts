import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ ethers, deployments, getNamedAccounts }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await ethers.getContractFactory('deterministic-deployment-proxy');

  await deploy('deterministic-deployment-proxy', {
    from: deployer,
    log: true,
  });
};

func.tags = ['Singleton'];
export default func;
