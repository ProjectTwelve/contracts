import { deployments, ethers } from 'hardhat';
import {
  ERC1155Delegate,
  ERC721Delegate,
  P12AssetFactoryUpgradable,
  P12MineUpgradeable,
  P12Token,
  P12CoinFactoryUpgradeable,
  SecretShopUpgradable,
  GaugeControllerUpgradeable,
  VotingEscrow,
} from '../typechain';
import { Contract } from 'ethers';

export declare type ExternalContract = {
  uniswapFactory: Contract;
  uniswapRouter: Contract;
  weth: Contract;
};

export declare type EconomyContract = {
  p12Token: P12Token;
  p12CoinFactory: P12CoinFactoryUpgradeable;
  p12AssetFactory: P12AssetFactoryUpgradable;
  p12SecretShop: SecretShopUpgradable;
  erc1155delegate: ERC1155Delegate;
  erc721delegate: ERC721Delegate;
  p12Mine: P12MineUpgradeable;
  gaugeController: GaugeControllerUpgradeable;
  votingEscrow: VotingEscrow;
};

export async function getContract<T extends Contract>(contractName: string) {
  return await ethers.getContractAt<T>(contractName, (await deployments.get(contractName)).address);
}

export async function deployExternal(): Promise<ExternalContract> {
  return {
    uniswapFactory: await getContract('UniswapV2Factory'),
    uniswapRouter: await getContract('UniswapV2Router02'),
    weth: await getContract('WETH9'),
  };
}

export async function deployEconomyContract(): Promise<EconomyContract> {
  return {
    p12Token: await getContract<P12Token>('P12Token'),
    p12CoinFactory: await getContract<P12CoinFactoryUpgradeable>('P12CoinFactoryUpgradeable'),
    p12AssetFactory: await getContract<P12AssetFactoryUpgradable>('P12AssetFactoryUpgradable'),
    p12SecretShop: await getContract<SecretShopUpgradable>('SecretShopUpgradable'),
    erc1155delegate: await getContract<ERC1155Delegate>('ERC1155Delegate'),
    erc721delegate: await getContract<ERC721Delegate>('ERC721Delegate'),
    votingEscrow: await getContract<VotingEscrow>('VotingEscrow'),
    gaugeController: await getContract<GaugeControllerUpgradeable>('GaugeControllerUpgradeable'),
    p12Mine: await getContract<P12MineUpgradeable>('P12MineUpgradeable'),
  };
}

export async function setUp(ec: EconomyContract, ex: ExternalContract) {
  const accounts = await ethers.getSigners();
  const admin = accounts[0];

  await ec.p12CoinFactory.setP12Mine(ec.p12Mine.address);
  await ec.p12CoinFactory.setGaugeController(ec.gaugeController.address);
  await ec.gaugeController.addType('liquidity', 1n * 10n ** 18n);

  await ec.erc1155delegate.grantRole(await ec.erc1155delegate.DELEGATION_CALLER(), ec.p12SecretShop.address);
  await ec.erc721delegate.grantRole(await ec.erc1155delegate.DELEGATION_CALLER(), ec.p12SecretShop.address);

  await ec.erc1155delegate.grantRole(await ec.erc1155delegate.PAUSABLE_CALLER(), admin.address);
  await ec.erc721delegate.grantRole(await ec.erc721delegate.PAUSABLE_CALLER(), admin.address);

  await ec.p12SecretShop.updateCurrencies([ec.p12Token.address], []);
  await ec.p12SecretShop.updateDelegates([ec.erc1155delegate.address, ec.erc721delegate.address], []);
}

export const fixtureAll = deployments.createFixture(async ({ deployments, getNamedAccounts, ethers }, options) => {
  const ex = await deployExternal();
  const ec = await deployEconomyContract();
  await setUp(ec, ex);
  return { ...ex, ...ec };
});
