import { formatBytes32String, keccak256 } from 'ethers/lib/utils';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const p12CoinFactoryUpgradeable = await get('P12CoinFactoryUpgradeable');
  const veP12 = await get('VotingEscrow');

  await deploy('GaugeControllerUpgradeable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          args: [owner, veP12.address, p12CoinFactoryUpgradeable.address],
        },
      },
    },
    log: true,
    deterministicDeployment: keccak256(formatBytes32String('P12_Economy_V1')),
  });
};
func.tags = ['GaugeController'];
export default func;
