import { ethers } from 'hardhat';

async function main() {
  // router : 0x6EbfB12A7a6B10a8123BD34Ef28b43EeF5DAdD02
  // factory: 0x43c6F5D9B18CD2da1ae910D8a321216fC96471e7
  // 1.17
  const P12FACTORY = await ethers.getContractFactory('P12CoinFactoryUpgradeable');
  const p12CoinFactory = await P12FACTORY.attach(
    '0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722', // 0x0CE1Eb4f32b5CFEeDDb375341175C81709716Cf7 p12TestNet
  );
  // 0x839A28f16c5ebFA8E4693e9b068325477E7f268B 1.17
  // 0xfeDb5e3a2783D4aB876f262d5eD522CD13d3559E 1.18
  // check uniswapRouter , uniswapFactory

  console.log('uniswap router address', await p12CoinFactory.uniswapRouter());
  console.log('uniswap factory address', await p12CoinFactory.uniswapFactory());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
