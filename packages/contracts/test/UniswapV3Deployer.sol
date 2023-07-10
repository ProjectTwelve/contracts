// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { Vm } from 'forge-std/Vm.sol';

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import { stdJson } from 'forge-std/StdJson.sol';

library UniswapV3Deployer {
  address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

  Vm constant vm = Vm(HEVM_ADDRESS);

  function deployUniswapV3Factory() public returns (address v3Factory) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(
      root,
      '/node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json'
    );

    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));

    assembly {
      v3Factory := create(0, add(bytecode, 0x20), mload(bytecode))
      if iszero(extcodesize(v3Factory)) {
        revert(0, 0)
      }
    }
  }

  function deployWETH9() public returns (address WETH9) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(root, '/node_modules/canonical-weth/build/contracts/WETH9.json');

    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));

    assembly {
      WETH9 := create(0, add(bytecode, 0x20), mload(bytecode))
      if iszero(extcodesize(WETH9)) {
        revert(0, 0)
      }
    }
  }

  function deployUniswapV3Router(address v3factory, address WETH9) public returns (address v3Router) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(
      root,
      '/node_modules/@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json'
    );
    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));
    bytes memory args = abi.encode(v3factory, WETH9);

    assembly {
      v3Router := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(v3Router)) {
        revert(0, 0)
      }
    }
  }

  function deployNFTPositionDescriptor(
    address WETH9,
    string memory nativeCurrencyLabel
  ) public returns (address tokenDescriptor) {
    if (bytes(nativeCurrencyLabel).length > 31) {
      revert('label too long');
    }
    string memory root = vm.projectRoot();
    string memory path = string.concat(
      root,
      '/@uniswap/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json'
    );
    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));
    bytes memory args = abi.encode(nativeCurrencyLabel, WETH9);

    assembly {
      tokenDescriptor := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(tokenDescriptor)) {
        revert(0, 0)
      }
    }
  }

  function deployPosManager(address factory, address WETH9, address tokenDes) public returns (address posManager) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(
      root,
      '/@uniswap/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json'
    );
    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));
    bytes memory args = abi.encode(factory, tokenDes, WETH9);

    assembly {
      posManager := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(posManager)) {
        revert(0, 0)
      }
    }
  }
}
