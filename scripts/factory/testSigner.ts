import { ethers } from 'hardhat';

async function main() {
  const owner = await ethers.getSigners();
  console.log(owner);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
