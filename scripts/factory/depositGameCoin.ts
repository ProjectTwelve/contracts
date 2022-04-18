import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

async function main() {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  [admin, user] = await ethers.getSigners();
  const p12FactoryAddress = '0xDEC0EAB90159aE6E63485d2BE0765fb274Fe9a59';
  const gameCoinAddress = '0xDd97F6b1C83E28159bBf6a152559Ad5DfDdBd025';
  const P12V0ERC20 = await ethers.getContractFactory('P12V0ERC20');
  const p12V0erc20 = await P12V0ERC20.attach(gameCoinAddress);
  const amountGameCoin = 1n * 10n ** 18n;
  const userId = '123';
  await p12V0erc20.connect(admin).approve(p12FactoryAddress, amountGameCoin);
  await p12V0erc20.connect(admin).transferWithAccount(p12FactoryAddress, userId, amountGameCoin);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
