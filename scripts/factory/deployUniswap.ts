import env, { ethers } from 'hardhat';
import * as compiledUniswapFactory from '@uniswap/v2-core/build/UniswapV2Factory.json';
import * as compiledUniswapRouter from '@uniswap/v2-periphery/build/UniswapV2Router02.json';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const admin = (await ethers.getSigners())[0];
    const weth = '0x0EE3F0848cA07E6342390C34FcC7Ea9D0217a47d';
    // deploy uniswap
    const UNISWAPV2ROUTER = new ethers.ContractFactory(compiledUniswapRouter.abi, compiledUniswapRouter.bytecode, admin);
    const UNISWAPV2FACTORY = new ethers.ContractFactory(
      compiledUniswapFactory.interface,
      compiledUniswapFactory.bytecode,
      admin,
    );
    const uniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);

    const uniswapV2Router02 = await UNISWAPV2ROUTER.connect(admin).deploy(uniswapV2Factory.address, weth);

    console.log('uniswapV2Factory: ', uniswapV2Factory.address, 'uniswapV2Router: ', uniswapV2Router02.address);
  } else if (env.network.name === 'rinkeby') {
    console.log('nothing happened');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
