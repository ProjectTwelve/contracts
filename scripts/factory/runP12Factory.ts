import { ethers } from 'hardhat';

async function main() {
  // gasPrice 1450990637
  // GasLimit 29024088

  // p12 factory 0xdA00fe766557ae056B1Da6bcc5ee239C987fBe08
  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const P12Factory = await P12FACTORY.attach('0x87b43f48009AC4E59d4bb520d510aD89fb8eA86a');

  // P12 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = await ERC20.attach('0x2844B158Bcffc0aD7d881a982D464c0ce38d8086');

  await P12Factory.register('1101', '0xfeD03676c595DD1F1c6716a446cD44B4C90AD290');

  const name = 'GameCoinTest002';
  const symbol = 'GC002';
  const gameId = '1102';
  const gameCoinIconUrl =
    'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
  const amountGameCoin = BigInt(2000) * BigInt(10) ** 18n;
  const amountP12 = BigInt(100) * BigInt(10) ** 18n;

  // await P12.approve(P12Factory.address, amountP12);
  // await P12Factory.create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
