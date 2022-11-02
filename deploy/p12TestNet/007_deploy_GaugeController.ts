import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer } = await getNamedAccounts();

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
          // TODO: add owner args when deploy
          args: [veP12.address, p12CoinFactoryUpgradeable.address],
        },
      },
    },
    log: true,
  });
};
func.tags = ['GaugeController'];
export default func;
