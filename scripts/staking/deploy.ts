import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const p12factory = '0x3288095c0033E33DcD25bf2cf439B848b45DFB70';
    const reward = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const blockStart = 638846;
    const delayK = 60;
    const delayB = 60;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [reward, p12factory, blockStart, delayK, delayB],
      {
        kind: 'uups',
      },
    );
    console.log('p12 Mine proxy contract', p12MineUpgradeable.address);
    // 0xc0b26Ee84984dD839AeCa6Ecc3037E966F7D32Ca
  } else if (env.network.name === 'rinkeby') {
    const p12factory = '0xA2C44E2d4DEC9B9e9C1AA2e508eD645EE3AE8dF7';
    const reward = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
    const blockStart = 10680803;
    const delayK = 1;
    const delayB = 1;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [reward, p12factory, blockStart, delayK, delayB],
      {
        kind: 'uups',
      },
    );

    console.log('p12 Mine proxy contract', p12MineUpgradeable.address);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
