import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, execute } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('OaoNFTReceiver', {
    from: deployer,
    args: [deployer],
    log: true,
  });

  await execute('OaoNFTReceiver', { from: deployer, log: true }, 'updateDstValidity', 20736, true);
};

func.tags = ['OaoNFTReceiver'];

export default func;
