import { formatBytes32String, keccak256 } from 'ethers/lib/utils';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy('UniswapV2Factory', {
    from: deployer,
    args: [deployer],
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });

  await deploy('WETH9', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });

  await deploy('UniswapV2Router02', {
    from: deployer,
    args: [(await get('UniswapV2Factory')).address, (await get('WETH9')).address],
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });
};
func.tags = ['Uniswap', 'WETH'];
export default func;
