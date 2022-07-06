import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const reward = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const p12factory = '0xd0f87C9de240cB25e25d77e2AD0Ae1E3A358b3B6';
    const gaugeController = '0x7d1a5e173996F2926e710E60C5361A3506502BB6';
    const votingEscrow = '0x1d8C8fd6762047d0eA81a8Da301D71249b00156c';
    const delayK = 60;
    const delayB = 60;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [reward, p12factory, gaugeController, votingEscrow, delayK, delayB],
      {
        kind: 'uups',
      },
    );
    console.log('p12 Mine proxy contract', p12MineUpgradeable.address);
    // 0xDDaa16B7C64303A3dD7821f18D205975E7740dea
  } else if (env.network.name === 'rinkeby') {
    const reward = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
    const p12factory = '0x0eD3D2A2ADdCcbbD9EF2B4A953FEB19c4377399C';
    const gaugeController = '0x81988148aefA137241f1B866b5FCcC9c3389B3b7';
    const votingEscrow = '0x427fbf5ae3b2684D6136a63D14BC7ABf963f6E7c';
    const delayK = 60;
    const delayB = 60;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [reward, p12factory, gaugeController, votingEscrow, delayK, delayB],
      {
        kind: 'uups',
      },
    );
    console.log('p12 Mine proxy contract', p12MineUpgradeable.address);
    // 0xb28cA31763eeC9A25C48d6Bf1dE5982A463932Fe
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
