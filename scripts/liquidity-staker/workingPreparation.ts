import { ethers, upgrades } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

// accounts info

async function accountsInfo(): Promise<SignerWithAddress[]> {
  return await ethers.getSigners();
}

// deploy weth
export async function deployWeth(): Promise<Contract> {
  const WETH = await ethers.getContractFactory('WETH9');
  const weth = await WETH.deploy();
  console.log('WETH contract deploy success');
  return weth;
}

// deploy UniswapV2Factory
export async function deployUniswapV2Factory(): Promise<Contract> {
  const accounts = await accountsInfo();
  const UniswapV2Factory = await ethers.getContractFactory('UniswapV2Factory');
  const uniswapV2Factory = await UniswapV2Factory.deploy(accounts[0].address);
  console.log('UniswapV2Factory contract deploy success');
  return uniswapV2Factory;
}

// deploy uniswapV2Router
export async function deployUniswapV2Router(
  uniswapV2Factory: Contract,
  weth: Contract,
  adminAddress: string,
): Promise<Contract> {
  const UniswapV2Router02 = await ethers.getContractFactory('UniswapV2Router02');
  const router = await UniswapV2Router02.deploy(uniswapV2Factory.address, weth.address, adminAddress);
  console.log('uniswapV2Router02 contract deploy success');
  return router;
}

// deploy p12
export async function deployP12coin(): Promise<Contract> {
  const p12COIN = await ethers.getContractFactory('ERC20FixedSupply');
  const p12 = await p12COIN.deploy('ProjectTwelve', 'P12', 100000000n * 10n ** 18n);
  console.log('p12coin contract deploy success');
  return p12;
}

// deploy LpToken
export async function deployLpToken(): Promise<Contract> {
  const LpToken = await ethers.getContractFactory('LpToken');
  const lp = await LpToken.deploy('liquidity pool token', 'LpToken', 100000000n * 10n ** 18n);
  console.log('LpToken contract deploy success');
  return lp;
}

// deploy p12factoryProxy
export async function deployP12V0FactoryUpgradeable(
  p12: Contract,
  uniswapV2Factory: Contract,
  router: Contract,
): Promise<Contract> {
  const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const p12V0FactoryUpgradeable = await upgrades.deployProxy(
    P12V0FactoryUpgradeable,
    [p12.address, uniswapV2Factory.address, router.address],
    { kind: 'uups' },
  );
  console.log('p12Factory contract deploy successfully!');
  return p12V0FactoryUpgradeable;
}
