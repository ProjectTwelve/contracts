import { formatBytes32String } from 'ethers/lib/utils';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const v3 = await deploy('UniswapV3Factory', {
    from: deployer,
    args: [],
    log: true,
  });

  const weth = await deploy('WETH9', {
    from: deployer,
    args: [],
    log: true,
  });

  await deploy('SwapRouter', {
    from: deployer,
    args: [v3.address, weth.address],
    log: true,
  });

  const desLib = await deploy('NFTDescriptor', {
    from: deployer,
    args: [],
    log: true,
  });

  const nftDes = await deploy('NonfungibleTokenPositionDescriptor', {
    from: deployer,
    args: [weth.address, formatBytes32String('P12')],
    libraries: { NFTDescriptor: desLib.address },
    log: true,
  });

  await deploy('NonfungiblePositionManager', {
    from: deployer,
    args: [v3.address, weth.address, nftDes.address],
    log: true,
  });

  await deploy('Quoter', {
    from: deployer,
    args: [v3.address, weth.address],
    log: true,
  });
};
func.tags = ['UniswapV3'];
export default func;
