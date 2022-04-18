// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from 'hardhat';

async function main() {
  const developer = (await ethers.getSigners())[0];

  // console.log(developer.address);

  const p12coin = await ethers.getContractAt('P12Coin', '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086');
  const weth = await ethers.getContractAt('WETH9', '0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15');

  const P12ExchangeUpgradableF = await ethers.getContractFactory('P12ExchangeUpgradable');

  const p12exchange = await upgrades.deployProxy(P12ExchangeUpgradableF, [0, weth.address], {
    kind: 'uups',
  });
  const ERC1155DelegateF = await ethers.getContractFactory('ERC1155Delegate');

  // deploy delegate
  const erc1155delegate = await ERC1155DelegateF.deploy();
  // Give Role to exchange contract
  await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), p12exchange.address);

  // Give Role to developer
  await erc1155delegate.grantRole(await erc1155delegate.DELEGATION_CALLER(), developer.address);

  // Add delegate
  await (
    await ethers.getContractAt('P12ExchangeUpgradable', p12exchange.address)
  ).updateDelegates([erc1155delegate.address], []);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
