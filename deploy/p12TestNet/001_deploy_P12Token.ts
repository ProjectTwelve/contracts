import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'ethers/lib/utils';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('P12Token', {
    from: deployer,
    // TODO: add owner args when deploy
    args: ['P12Token', 'P12', String(parseEther('10000'))],
    log: true,
  });
};
func.tags = ['P12Token'];
export default func;
