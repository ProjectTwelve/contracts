import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy, get } = deployments;

  const { deployer } = await getNamedAccounts();

  const p12 = await get('P12Token');
  const p12CoinFactoryUpgradeable = await get('P12CoinFactoryUpgradeable');
  const gaugeControllerUpgradeable = await get('GaugeControllerUpgradeable');

  await deploy('P12MineUpgradeable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          // TODO: add owner args when deploy
          args: [
            p12.address,
            p12CoinFactoryUpgradeable.address,
            gaugeControllerUpgradeable.address,
            60,
            60,
            ethers.BigNumber.from(5n * 10n ** 17n),
          ],
        },
      },
    },
    log: true,
  });
};
func.tags = ['Mine'];
export default func;
