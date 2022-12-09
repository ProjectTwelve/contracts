import { formatBytes32String, keccak256 } from 'ethers/lib/utils';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer, owner } = await getNamedAccounts();

  const p12CoinFactoryUpgradeable = await get('P12CoinFactoryUpgradeable');

  await deploy('P12AssetFactoryUpgradable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [owner, p12CoinFactoryUpgradeable.address],
        },
      },
    },
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });
};
func.tags = ['P12AssetFactory'];

export default func;
