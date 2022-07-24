import { ethers } from 'hardhat';

async function main() {
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = await ERC20.deploy('ProjectTwelve', 'P12', 100000000n * 10n ** 18n);

  // p12 address 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
  // p12 0x7154f7219F5E0F1EbF8C2dbBA1bCF8Fb36f2c5f3 p12TestNet
  // p12 0xd1190C53dFF162242EE5145cFb1C28dA75B921f3 p12 TestNet
  console.log('ProjectTwelve address : ', P12.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
