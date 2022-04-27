import { ethers } from 'hardhat';

async function main() {
  const Weth = ethers.getContractFactory('WETH9');
  const weth = (await Weth).deploy();
  console.log('weth address', (await weth).address);
  // p12Test Net 0x800D5A6d040Ef3Cb2230E06b7dE26b638af7C5cA 02/07
  // p12Test Net 0x7e556c95FC279379382c5f181967a7C5f6f8BcAf 02/08
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
