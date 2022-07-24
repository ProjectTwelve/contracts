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

factory

> Game token creation factory which allow developer to create game coin and manage minting process. Cast delay is included here.

secretShop

> Nft exchange contract which allows users to trade nft with token.

sftFactory

> Semi fungible token (sft) creation factory. Developers make their game assets on chain.

staking

> lp token holders stake their lp token to earn rewards. Rewards are decided by veP12 staked.

# Get Started

Requirement:

- Node >= 14
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
