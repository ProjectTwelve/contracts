import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const P12V0FactoryUpgradeableF = await ethers.getContractFactory('P12V0FactoryUpgradeable2');

    const proxyAddr = '0x3288095c0033E33DcD25bf2cf439B848b45DFB70';

    // const p12Token = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    // const uniswapV2Factory = '0x8C2543578eFEd64343C63e9075ed70F1d255D1c6';
    // const uniswapV2Router = '0x71A3B75A9A774EB793A44a36AF760ee2868912ac';
    await upgrades.upgradeProxy(proxyAddr, P12V0FactoryUpgradeableF);

    console.log('proxy contract', proxyAddr);
  } else if (env.network.name === 'rinkeby') {
    console.log('nothing happen');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
