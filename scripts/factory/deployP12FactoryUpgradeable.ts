import { ethers, upgrades } from 'hardhat';

async function main() {
  const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const p12Address = '0xd1190C53dFF162242EE5145cFb1C28dA75B921f3';
  const uniswapV2Factory = '0x47Ce8814257d598E126ae5CD8b933D28a4719B66';
  const uniswapV2Router = '0x7c3ad1f15019acfed2c7b5f05905008f39e44560';
  const p12V0FactoryUpgradeable = await upgrades.deployProxy(
    P12V0FactoryUpgradeable,
    [p12Address, uniswapV2Factory, uniswapV2Router],
    { kind: 'uups' },
  );
  console.log('proxy contract', p12V0FactoryUpgradeable.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
