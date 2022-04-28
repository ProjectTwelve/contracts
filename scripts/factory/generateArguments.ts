import { ethers } from 'hardhat';
import { Interface } from '@ethersproject/abi';
import { DeployProxyOptions } from '@openzeppelin/hardhat-upgrades/src/utils';

async function main() {
  const P12V0FactoryUpgradeable = await ethers.getContractFactory('P12V0FactoryUpgradeable');
  const p12Address = '0xd1190C53dFF162242EE5145cFb1C28dA75B921f3';
  const uniswapV2Factory = '0x47Ce8814257d598E126ae5CD8b933D28a4719B66';
  const uniswapV2Router = '0x7c3ad1f15019acfed2c7b5f05905008f39e44560';

  // const opts = { kind: "uups" };

  const opts: DeployProxyOptions = { kind: 'uups' };
  console.log('opts.initializer', opts.initializer);
  console.log('opts kind', opts.kind);
  const data = getInitializerData(
    P12V0FactoryUpgradeable.interface,
    [p12Address, uniswapV2Factory, uniswapV2Router],
    opts.initializer,
  );
  console.log(data);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

function getInitializerData(contractInterface: Interface, args: unknown[], initializer?: string | false): string {
  if (initializer === false) {
    return '0x';
  }

  const allowNoInitialization = initializer === undefined && args.length === 0;
  initializer = initializer ?? 'initialize';

  try {
    const fragment = contractInterface.getFunction(initializer);
    console.log(fragment);
    return contractInterface.encodeFunctionData(fragment, args);
  } catch (e: unknown) {
    if (e instanceof Error) {
      if (allowNoInitialization && e.message.includes('no matching function')) {
        return '0x';
      }
    }
    throw e;
  }
}
