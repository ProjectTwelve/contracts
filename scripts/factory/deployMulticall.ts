import { ethers } from 'hardhat';

async function main() {
  const Multicall = ethers.getContractFactory('Multicall');
  const multicall = (await Multicall).deploy();
  console.log('multicall address', (await multicall).address); // p12TestNet 0x7C3ad1f15019ACfEd2C7b5f05905008f39e44560
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
