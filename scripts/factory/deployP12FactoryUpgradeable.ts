import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'p12TestNet') {
    const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    const p12Address = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
    const uniswapV2Factory = '0x913d71546cC9FBB06b6F9d2ADEb0C58EFEF7a690';
    const uniswapV2Router = '0x7320C150D5fd661Fb1fB7af19a6337F3d099b41f';
    const p12V0FactoryUpgradeable = await upgrades.deployProxy(
      P12V0FactoryUpgradeable,
      [p12Address, uniswapV2Factory, uniswapV2Router, 86400, ethers.utils.randomBytes(32)],
      { kind: 'uups' },
    );
    console.log('proxy contract', p12V0FactoryUpgradeable.address);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
