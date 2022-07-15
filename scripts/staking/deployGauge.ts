import env, { ethers, upgrades } from 'hardhat';

async function main() {
  const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
  if (env.network.name === 'p12TestNet') {
    const votingEscrow = '0x1d8C8fd6762047d0eA81a8Da301D71249b00156c';
    const p12V0Factory = '0xd0f87C9de240cB25e25d77e2AD0Ae1E3A358b3B6';
    const gaugeController = await upgrades.deployProxy(GaugeController, [votingEscrow, p12V0Factory]);
    console.log('gaugeController contract', gaugeController.address);
    // 0x7d1a5e173996F2926e710E60C5361A3506502BB6
  } else if (env.network.name === 'rinkeby') {
    const votingEscrow = '0x427fbf5ae3b2684D6136a63D14BC7ABf963f6E7c';
    const p12V0Factory = '0x5dceAa4A7aCFc938a6Ea121EEE976358e0df41E8';
    const gaugeController = await upgrades.deployProxy(GaugeController, [votingEscrow, p12V0Factory]);
    console.log('gaugeController contract', gaugeController.address);
    // 0x81988148aefA137241f1B866b5FCcC9c3389B3b7
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
