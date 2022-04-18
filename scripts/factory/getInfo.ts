import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

async function main() {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  [admin, user] = await ethers.getSigners();

  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const p12Factory = await P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');
  const gameCoinAddress = '0x24c9238C4C8501E028DC129ea3a29745d201D1d6';
  const gameId = await p12Factory.allGameCoins(gameCoinAddress);
  const developer = await p12Factory.allGames(gameId);
  console.log('gameId', gameId);
  console.log('developer address', developer);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
