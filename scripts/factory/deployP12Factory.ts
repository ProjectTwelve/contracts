import { ethers } from 'hardhat';

async function main() {
  // router : 0x6EbfB12A7a6B10a8123BD34Ef28b43EeF5DAdD02
  // factory: 0x43c6F5D9B18CD2da1ae910D8a321216fC96471e7
  // 1.17
  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const p12Factory = await P12FACTORY.deploy(
    '0xfeD03676c595DD1F1c6716a446cD44B4C90AD290', // admin
    '0xfeD03676c595DD1F1c6716a446cD44B4C90AD290',
    '0xE76701C2fE67A56A03e1bEb88E8A954537C30b54', // uniswap router 0xE76701C2fE67A56A03e1bEb88E8A954537C30b54 1.26
    '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086', // p12 token
    '0x53457536bd7C93D91c1FC12214Fb8FF8E7D86315', // uniswapFactory 0x53457536bd7C93D91c1FC12214Fb8FF8E7D86315 1.26
  );
  // 0x839A28f16c5ebFA8E4693e9b068325477E7f268B 1.17
  // 0xfeDb5e3a2783D4aB876f262d5eD522CD13d3559E 1.18
  // check uniswapRouter , uniswapFactory

  // console.log(p12Factory);
  console.log(await p12Factory.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
