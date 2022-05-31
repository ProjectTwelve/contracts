import { ethers, upgrades } from 'hardhat';
import {
  ERC1155Delegate,
  ERC721Delegate,
  P12AssetFactoryUpgradable,
  P12MineUpgradeable,
  P12Token,
  P12V0FactoryUpgradeable,
  SecretShopUpgradable,
  GaugeControllerUpgradeable,
  VotingEscrow,
} from '../typechain';
import { Contract } from 'ethers';
import * as compiledUniswapFactory from '@uniswap/v2-core/build/UniswapV2Factory.json';
import * as compiledUniswapRouter from '@uniswap/v2-periphery/build/UniswapV2Router02.json';
import * as compiledWETH from 'canonical-weth/build/contracts/WETH9.json';

export declare type ExternalContract = {
  uniswapFactory: Contract;
  uniswapRouter: Contract;
  weth: Contract;
};

export declare type EconomyContract = {
  p12Token: P12Token;
  p12V0Factory: P12V0FactoryUpgradeable;
  p12AssetFactory: P12AssetFactoryUpgradable;
  p12SecretShop: SecretShopUpgradable;
  erc1155delegate: ERC1155Delegate;
  erc721delegate: ERC721Delegate;
  p12Mine: P12MineUpgradeable;
  gaugeController: GaugeControllerUpgradeable;
  votingEscrow: VotingEscrow;
};

export async function deployExternal(): Promise<ExternalContract> {
  const accounts = await ethers.getSigners();
  const admin = accounts[0];

  // deploy weth
  const WETH = new ethers.ContractFactory(compiledWETH.abi, compiledWETH.bytecode, admin);
  const weth = await WETH.deploy();

  // deploy uniswap
  const UNISWAPV2ROUTER = new ethers.ContractFactory(compiledUniswapRouter.abi, compiledUniswapRouter.bytecode, admin);
  const UNISWAPV2FACTORY = new ethers.ContractFactory(compiledUniswapFactory.interface, compiledUniswapFactory.bytecode, admin);
  const uniswapV2Factory = await UNISWAPV2FACTORY.connect(admin).deploy(admin.address);
  const uniswapV2Router02 = await UNISWAPV2ROUTER.connect(admin).deploy(uniswapV2Factory.address, weth.address);

  return {
    uniswapFactory: uniswapV2Factory,
    uniswapRouter: uniswapV2Router02,
    weth: weth,
  };
}

export async function deployEconomyContract(externalContract: ExternalContract): Promise<EconomyContract> {
  const accounts = await ethers.getSigners();
  const admin = accounts[0];
  const P12Token = await ethers.getContractFactory('P12Token');
  const P12V0FactoryF = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const P12AssetFactoryF = await ethers.getContractFactory('P12AssetFactoryUpgradable');
  const P12SecretShopF = await ethers.getContractFactory('SecretShopUpgradable');
  const ERC1155DelegateF = await ethers.getContractFactory('ERC1155Delegate');
  const ERC721DelegateF = await ethers.getContractFactory('ERC721Delegate');
  const P12MineF = await ethers.getContractFactory('P12MineUpgradeable');
  const GaugeController = await ethers.getContractFactory('GaugeControllerUpgradeable');
  const VotingEscrow = await ethers.getContractFactory('VotingEscrow');

  const p12Token = await P12Token.deploy('Project Twelve', 'P12', 10000n * 10n ** 18n);
  const p12V0Factory = await upgrades.deployProxy(P12V0FactoryF, [
    p12Token.address,
    externalContract.uniswapFactory.address,
    externalContract.uniswapRouter.address,
    86400,
    ethers.utils.randomBytes(32),
  ]);
  const p12AssetFactory = await upgrades.deployProxy(P12AssetFactoryF, [p12V0Factory.address]);
  const p12SecretShop = await upgrades.deployProxy(P12SecretShopF, [10n ** 5n, externalContract.weth.address]);
  const erc1155delegate = await ERC1155DelegateF.deploy();
  const erc721delegate = await ERC721DelegateF.deploy();
  const votingEscrow = await VotingEscrow.deploy(p12Token.address, 'Vote-escrowed P12', 'veP12');
  const gaugeController = await upgrades.deployProxy(GaugeController, [
    admin.address,
    votingEscrow.address,
    p12V0Factory.address,
  ]);
  const p12Mine = await upgrades.deployProxy(P12MineF, [
    p12Token.address,
    p12V0Factory.address,
    gaugeController.address,
    votingEscrow.address,
    60,
    60,
  ]);

  return {
    p12Token: p12Token,
    p12V0Factory: await ethers.getContractAt('P12V0FactoryUpgradeable', p12V0Factory.address),
    p12AssetFactory: await ethers.getContractAt('P12AssetFactoryUpgradable', p12AssetFactory.address),
    p12SecretShop: await ethers.getContractAt('SecretShopUpgradable', p12SecretShop.address),
    erc1155delegate: erc1155delegate,
    erc721delegate: erc721delegate,
    votingEscrow: votingEscrow,
    gaugeController: await ethers.getContractAt('GaugeControllerUpgradeable', gaugeController.address),
    p12Mine: await ethers.getContractAt('P12MineUpgradeable', p12Mine.address),
  };
}

export async function setUp(ec: EconomyContract) {
  const accounts = await ethers.getSigners();
  const admin = accounts[0];

  await ec.p12V0Factory.setP12Mine(ec.p12Mine.address);
  await ec.p12V0Factory.setGaugeController(ec.gaugeController.address);
  await ec.gaugeController.addType('liquidity', 1n * 10n ** 18n);

  await ec.erc1155delegate.grantRole(await ec.erc1155delegate.DELEGATION_CALLER(), ec.p12SecretShop.address);
  await ec.erc721delegate.grantRole(await ec.erc1155delegate.DELEGATION_CALLER(), ec.p12SecretShop.address);

  await ec.erc1155delegate.grantRole(await ec.erc1155delegate.PAUSABLE_CALLER(), admin.address);
  await ec.erc721delegate.grantRole(await ec.erc721delegate.PAUSABLE_CALLER(), admin.address);

  await ec.erc1155delegate.renounceRole(await ec.erc1155delegate.DEFAULT_ADMIN_ROLE(), admin.address);
  await ec.erc721delegate.renounceRole(await ec.erc721delegate.DEFAULT_ADMIN_ROLE(), admin.address);

  await ec.p12SecretShop.updateCurrencies([ec.p12Token.address], []);
  await ec.p12SecretShop.updateDelegates([ec.erc1155delegate.address, ec.erc721delegate.address], []);
}

export async function deployAll(): Promise<EconomyContract & ExternalContract> {
  const ex = await deployExternal();
  const ec = await deployEconomyContract(ex);
  await setUp(ec);

  return { ...ex, ...ec };
}

if (require.main === module) {
  deployAll().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
