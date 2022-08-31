import { DeploymentsManager } from 'hardhat-deploy/dist/src/DeploymentsManager';
import env from 'hardhat';
import { lazyObject } from 'hardhat/plugins';
import fs from 'fs-extra';
import path from 'path';

async function main() {
  const deploymentsManager = new DeploymentsManager(
    env,
    lazyObject(() => env.network), // IMPORTANT, else other plugin cannot set env.network before end, like solidity-coverage does here in the coverage task :  https://github.com/sc-forks/solidity-coverage/blob/3c0f3a5c7db26e82974873bbf61cf462072a7c6d/plugins/resources/nomiclabs.utils.js#L93-L98
  );
  await deploymentsManager.loadDeployments(false);
  const fileName = path.join(__dirname, 'deployments') + '/' + env.network.name + '.json';
  await deploymentsManager.export({ export: fileName });

  const OtherContract = ['P12GameCoin', 'P12Asset'];

  const content = fs.readJSONSync(fileName, { encoding: 'utf-8' });

  for (const c of OtherContract) {
    content.contracts[c] = {};
    content.contracts[c].abi = env.artifacts.readArtifactSync(c).abi;
  }

  fs.writeFileSync(fileName, JSON.stringify(content, null, '  '));
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
