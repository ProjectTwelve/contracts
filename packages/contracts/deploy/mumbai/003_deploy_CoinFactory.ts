import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { get, deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const p12Token = await get('P12Token');

  const gameCoinImpl = await get('P12GameCoin');

  // Be carefully: Check whether proxy contract is initialized successfully
  await deploy('P12CoinFactoryUpgradeable', {
    from: deployer,
    args: [],
    proxy: {
      proxyContract: 'ERC1967Proxy',
      proxyArgs: ['{implementation}', '{data}'],
      execute: {
        init: {
          methodName: 'initialize',
          // v3 factory 0x1F98431c8aD98523631AE4a59f267346ea31F984
          // https://mumbai.polygonscan.com/address/0x1F98431c8aD98523631AE4a59f267346ea31F984

          // v3 pos manager 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
          // https://mumbai.polygonscan.com/address/0xC36442b4a4522E871399CD717aBDD847Ab11FE88
          args: [
            deployer,
            p12Token.address,
            '0x1F98431c8aD98523631AE4a59f267346ea31F984',
            '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
            gameCoinImpl.address,
          ],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
