import { DeploymentsManager } from 'hardhat-deploy/dist/src/DeploymentsManager';
import env from 'hardhat';
import { lazyObject } from 'hardhat/plugins';
import path from 'path';

async function main() {
  const deploymentsManager = new DeploymentsManager(
    env,
    lazyObject(() => env.network), // IMPORTANT, else other plugin cannot set env.network before end, like solidity-coverage does here in the coverage task :  https://github.com/sc-forks/solidity-coverage/blob/3c0f3a5c7db26e82974873bbf61cf462072a7c6d/plugins/resources/nomiclabs.utils.js#L93-L98
  );
  await deploymentsManager.loadDeployments(false);
  await deploymentsManager.export({ export: path.join(__dirname, 'deployments') + '/' + env.network.name + '.json' });
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
