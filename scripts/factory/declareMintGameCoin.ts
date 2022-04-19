import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

async function main() {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  [admin, user] = await ethers.getSigners();
  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const P12Factory = await P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');

  // P12 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = await ERC20.attach('0xd1190C53dFF162242EE5145cFb1C28dA75B921f3');

  // mint
  const amountGameCoin = BigInt(10) * BigInt(10) ** 18n;
  const amountP12 = BigInt(10) * BigInt(10) ** 18n;

  await P12.connect(user).approve(P12Factory.address, amountP12);
  console.log('mint delay', await P12Factory.getMintDelay('0x24c9238C4C8501E028DC129ea3a29745d201D1d6', amountGameCoin));
  await P12Factory.connect(user).declareMintCoin('1001', '0x24c9238C4C8501E028DC129ea3a29745d201D1d6', amountGameCoin);
  // await P12Factory.executeMint("0x5a88a8375bc71707eb1743eB24afc9d6fbeeD191");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
