import env, { ethers, upgrades } from 'hardhat';

async function main() {
  if (env.network.name === 'rinkeby') {
    const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
    const p12Token = '0x2844B158Bcffc0aD7d881a982D464c0ce38d8086';
    const uniswapV2Factory = '0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f';
    const uniswapV2Router = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';

    const p12V0Factory = await upgrades.deployProxy(P12V0FactoryUpgradeable, [
      p12Token,
      uniswapV2Factory,
      uniswapV2Router,
      86400,
      ethers.utils.randomBytes(32),
    ]);

    // 0xc98d4fe35EfEB4C554961D893C2A18e4fE7Bb740
    console.log('p12V0Factory address is', p12V0Factory.address);

    // transfer ownership
    const gnosis = '0x3247bd464B08de78ad8c53d942FaC2eb61bA0d01';
    const factory = await P12V0FactoryUpgradeable.attach(p12V0Factory.address);
    await factory.transferOwnership(gnosis, false);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
