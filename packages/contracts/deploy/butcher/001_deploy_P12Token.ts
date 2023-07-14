import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'ethers/lib/utils';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('P12Token', {
    from: deployer,
    args: [deployer, 'P12Token', 'P12', parseEther(Number(10_000_000_000).toString())],
    log: true,
  });
};
func.tags = ['P12Token'];
export default func;
