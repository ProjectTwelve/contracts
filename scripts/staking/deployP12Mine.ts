import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const reward = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const p12factory = '0xaA65e38dC95c8709511440039d880232819406c4';
    const gaugeController = '0x2Ad82033AFD731CdD877462218d5eadD992f5723';
    const delayK = 60;
    const delayB = 60;
    const rate = 5n * 10n ** 17n;
    const P12MineUpgradeable = await ethers.getContractFactory('P12MineUpgradeable');
    const p12MineUpgradeable = await upgrades.deployProxy(
      P12MineUpgradeable,
      [reward, p12factory, gaugeController, delayK, delayB, rate],
      {
        kind: 'uups',
      },
    );
    console.log('p12 Mine proxy contract', p12MineUpgradeable.address);
    // 0x591a222E7E74AFd18c1e08441bC3ea3772Ccc18b
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
