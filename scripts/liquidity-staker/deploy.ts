import { ethers, upgrades } from 'hardhat';

async function main() {
  const p12factory = '0x588EC7f5f7AEe6c117bf924c6D1E9851582bA64c';
  const reward = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
  const timeStart = 10365707;
  const delayK = 60;
  const delayB = 60;
  const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
  const p12MineUpgradeable = await upgrades.deployProxy(P12MineUpgradeable, [reward, p12factory, timeStart, delayK, delayB], {
    kind: 'uups',
  });

  console.log('proxy contract', p12MineUpgradeable.address);
  // 0xc0b26Ee84984dD839AeCa6Ecc3037E966F7D32Ca
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
