import env, { ethers, upgrades } from 'hardhat';

async function main() {
  const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
  if (env.network.name === 'p12TestNet') {
    const votingEscrow = '0xd583619d365E150E81804DC9aa2276F1b2d44D11';
    const p12V0Factory = '0xaA65e38dC95c8709511440039d880232819406c4';
    const gaugeController = await upgrades.deployProxy(GaugeController, [votingEscrow, p12V0Factory]);
    console.log('gaugeController contract', gaugeController.address);
    // 0x2Ad82033AFD731CdD877462218d5eadD992f5723
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
