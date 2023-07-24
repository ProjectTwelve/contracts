import path from 'path';
import fs from 'fs-extra';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

export default async function verifyDeploymentOnScan(params: any, hre: HardhatRuntimeEnvironment): Promise<void> {
  await main(hre);
}

// If the contract does not require verification, just add it here
const whiteList: string[] = [
  'NFTDescriptor',
  'NonfungiblePositionManager',
  'NonfungibleTokenPositionDescriptor',
  'SwapRouter',
  'UniswapV3Factory',
  'WETH9',
];

function getNoVerifyFile(hre: HardhatRuntimeEnvironment) {
  const files: string[] = [];
  if (whiteList.length > 0) {
    whiteList.forEach((l) => {
      const pathFile = path.join(__dirname, '../deployments') + '/' + hre.network.name + '/' + l + '.json';
      files.push(pathFile);
    });
  }
  return files;
}

async function main(hre: HardhatRuntimeEnvironment) {
  const dir = path.join(__dirname, '../deployments') + '/' + hre.network.name;

  await travel(hre, dir);
}

async function travel(hre: HardhatRuntimeEnvironment, dir: string) {
  const promises = [];

  for (const file of fs.readdirSync(dir)) {
    const pathname = path.join(dir, file);
    const stat = fs.statSync(pathname);
    if (stat.isDirectory()) {
      travel(hre, pathname);
    } else {
      promises.push(verifyFile(hre, pathname));
    }
  }

  await Promise.all(promises);
}

async function verifyFile(hre: HardhatRuntimeEnvironment, fileName: string) {
  const reg = /.chainId|solcInputs|_Proxy/gi;
  const whiteList = getNoVerifyFile(hre);
  if (!whiteList.includes(fileName) && fileName.search(reg) === -1) {
    const content = fs.readJSONSync(fileName, { encoding: 'utf-8' });
    try {
      if (!content.implementation) {
        await verify(hre, content.address, content.args, content.storageLayout.storage[0]?.contract);
      }
    } catch (err) {
      const str: string = String(err);
      if (str.includes('Reason: Already Verified') || str.includes('Contract source code already verified')) {
        console.log(
          `${
            content.storageLayout.storage[0]
              ? content.storageLayout.storage[0].contract
              : `contract/` + fileName.split('/').pop()?.split('.')[0] + `.sol` + `:` + fileName.split('/').pop()?.split('.')[0]
          } at ${content.address} Already Verified`,
        );
      } else {
        console.log(
          `verify the ${
            content.storageLayout?.storage[0]
              ? content.storageLayout.storage[0].contract
              : `contract/` + fileName.split('/').pop()?.split('.')[0] + `.sol` + `:` + fileName.split('/').pop()?.split('.')[0]
          } at ${content.address} fail`,
          err,
        );
      }
    }
  }
}

async function verify(
  hre: HardhatRuntimeEnvironment,
  _contractAddress: string,
  _constructorArguments: string[],
  _contract?: string,
) {
  await hre.run('verify:verify', {
    address: _contractAddress,
    constructorArguments: _constructorArguments,
    contract: _contract,
    noCompile: true,
  });
}
