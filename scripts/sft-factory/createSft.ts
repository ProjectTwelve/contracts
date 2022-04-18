// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';

async function main() {
  const developer = (await ethers.getSigners())[1];

  const p12AssetFactoryAddr = '0x839A28f16c5ebFA8E4693e9b068325477E7f268B';

  const collectionAddr = '0xF60C0C3fA68387f05D2A5F7e6BA468fAaDB0dd62';

  const p12AssetFactory = await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactoryAddr);

  await p12AssetFactory.connect(developer).createAssetAndMint(
    collectionAddr,
    100,
    /* cSpell:disable */
    'ipfs://QmVZMakUubEr5Gaa5DAcunMjCWj5pkUMXav21bS7DTjySQ',
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
