import env from 'hardhat';
import path from 'path';
import fs from 'fs-extra';

const list = [
  '/Users/snow/contracts/deployments/rinkeby/P12Token.json',
  '/Users/snow/contracts/deployments/rinkeby/UniswapV2Factory.json',
  '/Users/snow/contracts/deployments/rinkeby/UniswapV2Router02.json',
  '/Users/snow/contracts/deployments/rinkeby/WETH9.json',
];
async function main() {
  const dir = path.join(__dirname, '../deployments') + '/' + env.network.name;
  travel(dir, async function (fileName) {
    const reg = /.chainId|solcInputs|_Proxy/gi;
    if (!list.includes(fileName) && fileName.search(reg) === -1) {
      const content = fs.readJSONSync(fileName, { encoding: 'utf-8' });
      try {
        if (!content.implementation) {
          if (content.storageLayout) {
            await verify(content.address, content.args, content.storageLayout.storage[0].contract);
          } else {
            await verify(content.address, content.args);
          }
        }
      } catch (err) {
        const str: string = String(err);
        if (str.includes('Reason: Already Verified') || str.includes('Contract source code already verified')) {
          console.log(`${content.storageLayout.storage[0].contract} at ${content.address} Already Verified`);
        } else {
          console.log(`verify the ${content.storageLayout.storage[0].contract} at ${content.address} fail`, err);
        }
      }
    }
  });
}

function travel(dir: string, callback: (arg0: string) => void) {
  fs.readdir(dir, (err, files) => {
    if (err) {
      console.log(err);
    } else {
      files.forEach((file) => {
        const pathname = path.join(dir, file);
        fs.stat(pathname, (err, stats) => {
          if (err) {
            console.log(err);
          } else if (stats.isDirectory()) {
            travel(pathname, callback);
          } else {
            callback(pathname);
          }
        });
      });
    }
  });
}

async function verify(_contractAddress: string, _constructorArguments: string[], _contract?: string) {
  await env.run('verify:verify', {
    address: _contractAddress,
    constructorArguments: _constructorArguments,
    contract: _contract,
  });
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
