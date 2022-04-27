import { ethers } from 'hardhat';

async function main() {
  const P12FACTORY = await ethers.getContractFactory('P12V0Factory');
  const P12Factory = await P12FACTORY.attach('0xF7fd4112CFf5da535BBFa3811D40fE9Aa61FA722');

  // P12 0x2844B158Bcffc0aD7d881a982D464c0ce38d8086
  const ERC20 = await ethers.getContractFactory('P12Token');
  const P12 = ERC20.attach('0x2844B158Bcffc0aD7d881a982D464c0ce38d8086');
  console.log('P12: ', P12.address);

  await P12Factory.executeMint(
    '0x24c9238C4C8501E028DC129ea3a29745d201D1d6',
    '0xe84e2d079a46c32c99afc118555051232f616853f4c928ab5b602fc3d2bba315',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
