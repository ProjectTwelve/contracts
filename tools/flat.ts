import { task, subtask } from 'hardhat/config';
import { DependencyGraph } from 'hardhat/internal/solidity/dependencyGraph';
import { ResolvedFile } from 'hardhat/types';
import fs from 'fs';

type FilesMap = {
  [key: string]: ResolvedFile;
};

function getSortedFiles(dependenciesGraph: DependencyGraph): ResolvedFile[] {
  const tsort = require('tsort');
  const graph = tsort();

  const filesMap: FilesMap = {};
  const resolvedFiles = dependenciesGraph.getResolvedFiles();

  resolvedFiles.forEach((f: ResolvedFile) => {
    filesMap[f.sourceName] = f;
  });

  for (const [from, deps] of dependenciesGraph.entries()) {
    for (const to of deps) {
      graph.add(to.sourceName, from.sourceName);
    }
  }

  const topologicalSortedNames = graph.sort();

  // If an entry has no dependency it won't be included in the graph, so we
  // add them and then dedup the array
  const withEntries: string[] = topologicalSortedNames.concat(resolvedFiles.map((f: ResolvedFile) => f.sourceName));

  const sortedNames = [...new Set(withEntries)];
  return sortedNames.map((n) => filesMap[n]);
}

function getFileWithoutImports(resolvedFile: any) {
  const IMPORT_SOLIDITY_REGEX = /^\s*import(\s+)[\s\S]*?;\s*$/gm;

  return resolvedFile.content.rawContent.replace(IMPORT_SOLIDITY_REGEX, '').trim();
}

subtask('flat:get-flattened-sources', 'Returns all contracts and their dependencies flattened').setAction(async (args, hre) => {
  const sourcePaths: string[] = await hre.run('compile:solidity:get-source-paths');

  let sourceNames: string[] = await hre.run('compile:solidity:get-source-names', {
    sourcePaths,
  });

  // filter interface and library
  sourceNames = sourceNames.filter((x: string) => {
    return !x.includes('interface') && !x.includes('library');
  });

  if (!fs.existsSync('flatten')) {
    fs.mkdirSync('flatten');
  } else {
    fs.rmdirSync('flatten', { recursive: true });
    fs.mkdirSync('flatten');
  }

  for (const sourceName of sourceNames) {
    let flattened = '';

    const tmp = sourceName.split('/').slice(1);
    tmp.splice(0, 0, 'flatten');
    const output = tmp.join('/');

    const dir = tmp.slice(0, tmp.length - 1).join('/');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const dependencyGraph: DependencyGraph = await hre.run('compile:solidity:get-dependency-graph', {
      sourceNames: [sourceName],
    });

    const sortedFiles = getSortedFiles(dependencyGraph);

    let isFirst = true;
    for (const file of sortedFiles) {
      if (!isFirst) {
        flattened += '\n';
      }
      flattened += `// File ${file.getVersionedName()}\n`;
      flattened += `${getFileWithoutImports(file)}\n`;

      isFirst = false;
    }

    // Remove every line started with "// SPDX-License-Identifier:"
    flattened = flattened.replace(/SPDX-License-Identifier:/gm, 'License-Identifier:');

    flattened = `// SPDX-License-Identifier: MIXED\n\n${flattened}`;

    // Remove every line started with "pragma experimental ABIEncoderV2;" except the first one
    flattened = flattened.replace(
      /pragma experimental ABIEncoderV2;\n/gm,
      (
        (i) => (m: string) =>
          !i++ ? m : ''
      )(0),
    );

    // Remove every line started with "pragma solidity ^0.8.0;" except the first one
    flattened = flattened.replace(
      /pragma solidity \^[0-9]\.[0-9]\.[0-9];\n/gm,
      (
        (i) => (m: string) =>
          !i++ ? m : ''
      )(0),
    );

    flattened = flattened.trim();
    console.log('Writing to', output);
    fs.writeFileSync(output, flattened);
  }
});

function addFlatTask(): void {
  task('flat', 'Flattens and prints contracts and their dependencies').setAction(async ({ files, output }, { run }) => {
    await run('flat:get-flattened-sources', {});
  });
}

export { addFlatTask };
