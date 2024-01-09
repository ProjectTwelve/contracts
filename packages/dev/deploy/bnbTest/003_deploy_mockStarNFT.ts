import { DeployFunction } from 'hardhat-deploy/types';
import { keccak256, stringToBytes } from 'viem';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('StarNFT', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: keccak256(stringToBytes('GalxeBadgeReceiverV2')),
  });
};

func.tags = ['MockStarNFT'];

export default func;
