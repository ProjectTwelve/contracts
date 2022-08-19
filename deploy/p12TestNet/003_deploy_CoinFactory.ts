import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat';

const func: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const p12Token = '0xeAc1F044C4b9B7069eF9F3eC05AC60Df76Fe6Cd0';
  const uniswapFactory = '0x8C2543578eFEd64343C63e9075ed70F1d255D1c6';
  const uniswapRouter = '0x71A3B75A9A774EB793A44a36AF760ee2868912ac';

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
          args: [p12Token, uniswapFactory, uniswapRouter, 86400, ethers.utils.randomBytes(32)],
        },
      },
    },
    log: true,
  });
};
func.tags = ['P12CoinFactory'];

export default func;
