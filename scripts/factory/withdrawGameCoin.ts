import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

async function main() {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  [admin, user] = await ethers.getSigners();

  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const P12Factory = await P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');

  const gameCoinAddress = '0x24c9238C4C8501E028DC129ea3a29745d201D1d6';
  const userAddress = '0xd67253b103eD0ac5132a443247370BdE856c515E';
  const amountGameCoin = 1n * 10n ** 18n;
  const tx = await P12Factory.connect(admin).withdraw(userAddress, gameCoinAddress, amountGameCoin);
  console.log('tx', tx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
