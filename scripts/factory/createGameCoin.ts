import { ethers } from 'hardhat';

async function main() {
  const [admin, user] = await ethers.getSigners();
  console.log('admin: ', admin.address, 'user: ', user.address);

  const P12FACTORY = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const P12Factory = P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');

  // P12 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
  // p12 0x7154f7219F5E0F1EbF8C2dbBA1bCF8Fb36f2c5f3 p12TestNet
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = ERC20.attach('0xd1190C53dFF162242EE5145cFb1C28dA75B921f3');

  const name = 'GameCoinTest001';
  const symbol = 'GC001';
  const gameId = '1001';
  const gameCoinIconUrl =
    'https://images.weserv.nl/?url=https://i0.hdslb.com/bfs/article/87c5b43b19d4065f837f54637d3932e680af9c9b.jpg';
  const amountGameCoin = BigInt(2000) * BigInt(10) ** 18n;
  const amountP12 = BigInt(100) * BigInt(10) ** 18n;

  await P12.connect(user).approve(P12Factory.address, amountP12);
  await P12Factory.connect(user).create(name, symbol, gameId, gameCoinIconUrl, amountGameCoin, amountP12);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
