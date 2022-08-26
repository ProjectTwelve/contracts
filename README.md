![License: GPL](https://img.shields.io/badge/license-GPLv3-blue)

# Project Twelve Economy Contracts

Project Twelve, P12 in short, is a Web3 gaming platform and game creator ecosystem. P12 aims to:

- Make game creation accessible
- Make game economy sustainable

Learn More:

- Whitepaper: <https://github.com/ProjectTwelve/whitepaper>
- Website: <https://p12.network>
- Discord: <https://discord.gg/p12>
- Twitter: <https://twitter.com/_p12_>
- Mirror: <https://mirror.xyz/p12.eth>

# Contracts

The contracts are in development and test currently, some will be changed until deployed to production network. Here are some explainations in brief detail below.

assetFactory

> Game Assets creation factory. Developers make their game props on chain.

coinFactory

> Game coin creation factory which allow developer to create game coin and manage minting process. Cast delay is included here.

secretShop

> Assets exchange contract which allows users to trade assets with coin.

staking

> Lp token holders stake their lp token to earn rewards. The reward is determined according to the proportion of their own lpToken in the pledge pool. The reward distribution weight for each staking pool is voted by veP12 according to the GaugeContoller contract.

# Get Started

Requirement:

- Node >= 16
- yarn(recommend)

Clone the repository

```shell
$ git clone https://github.com/ProjectTwelve/contracts
```

Install dependencies

```shell
$ yarn -D
```

Run all test

```shell
$ yarn test
```

# Copyright

Copyright © 2022 Project Twelve

Licensed under [GPL-3.0](LICENSE)
