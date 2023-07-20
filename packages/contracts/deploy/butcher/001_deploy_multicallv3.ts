import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('Multicall3', {
    from: deployer,
    log: true,
  });
};

func.tags = ['multicall'];
export default func;
