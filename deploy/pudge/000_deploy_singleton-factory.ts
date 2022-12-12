import { formatBytes32String, keccak256 } from 'ethers/lib/utils';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('deterministic-deployment-proxy', {
    from: deployer,
    log: true,
  });

  await deploy('Multicall3', {
    from: deployer,
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });
};

func.tags = ['Singleton'];
export default func;
