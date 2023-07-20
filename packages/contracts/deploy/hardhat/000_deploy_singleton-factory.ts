import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ ethers, deployments, getUnnamedAccounts }) {
  const { deploy } = deployments;
  const deployer = (await getUnnamedAccounts())[0];

  // await ethers.getContractFactory('deterministic-deployment-proxy');

  await deploy('deterministic-deployment-proxy', {
    from: deployer,
    log: true,
  });
};

func.tags = ['Singleton'];
export default func;
