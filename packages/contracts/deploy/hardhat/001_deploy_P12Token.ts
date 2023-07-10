import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'ethers/lib/utils';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  await deploy('P12Token', {
    from: deployer,
    args: [owner, 'P12Token', 'P12', String(parseEther((10 ** 10).toString()))],
    log: true,
  });
};
func.tags = ['P12Token'];
export default func;
