import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    const p12Token = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const uniswapV2Factory = '0x8C2543578eFEd64343C63e9075ed70F1d255D1c6';
    const uniswapV2Router = '0x71A3B75A9A774EB793A44a36AF760ee2868912ac';
    const p12V0FactoryUpgradeable = await upgrades.deployProxy(
      P12V0FactoryUpgradeable,
      [p12Token, uniswapV2Factory, uniswapV2Router, 86400, ethers.utils.randomBytes(32)],
      { kind: 'uups' },
    );
    console.log('proxy contract', p12V0FactoryUpgradeable.address);
    // 0xD3a76F2B93b093E89E0B753a4E8D2263680D6302
  } else if (env.network.name === 'rinkeby') {
    const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    const p12Token = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
    const uniswapV2Factory = '0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f';
    const uniswapV2Router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
    const p12V0FactoryUpgradeable = await upgrades.deployProxy(
      P12V0FactoryUpgradeable,
      [p12Token, uniswapV2Factory, uniswapV2Router, 86400, ethers.utils.randomBytes(32)],
      { kind: 'uups' },
    );

    console.log('proxy contract', p12V0FactoryUpgradeable.address);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
