import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const p12 = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';

  await deploy('VotingEscrow', {
    from: deployer,
    args: [p12, 'Vote-escrowed P12', 'veP12'],
    log: true,
  });
};
func.tags = ['veP12'];
export default func;
