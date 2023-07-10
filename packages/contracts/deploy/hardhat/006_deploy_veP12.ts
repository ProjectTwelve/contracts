import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const p12 = await get('P12Token');

  await deploy('VotingEscrow', {
    from: deployer,
    args: [owner, p12.address, 'Vote-escrowed P12', 'veP12'],
    log: true,
  });
};
func.tags = ['veP12'];
export default func;
