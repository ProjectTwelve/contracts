import { DeployFunction } from 'hardhat-deploy/types';
import { formatBytes32String, keccak256, parseEther } from 'ethers/lib/utils';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  await deploy('P12Token', {
    from: deployer,
    args: [owner, 'P2Token', 'P2', String(parseEther((10 ** 10).toString()))],
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });
};
func.tags = ['P12Token'];
export default func;
