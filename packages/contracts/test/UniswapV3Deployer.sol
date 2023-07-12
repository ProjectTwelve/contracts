// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.19;

import { Vm } from 'forge-std/Vm.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/console2.sol';
import { stdJson } from 'forge-std/StdJson.sol';

// import { NFTDescriptor } from 'src/test/uniswap/NFTDescriptor.sol';
// import { NonfungibleTokenPositionDescriptor } from 'src/test/uniswap/NonfungibleTokenPositionDescriptor.sol';

library UniswapV3Deployer {
  address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

  address constant NFT_DESCRIPTOR = address(bytes20(uint160(uint256(keccak256('uniswap nft descriptor library')))));

  Vm constant vm = Vm(HEVM_ADDRESS);

  function deployUniswapV3Factory() public returns (address v3Factory) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(root, '/vendor/UniswapV3Factory.json');

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
    string memory path = string.concat(root, '/vendor/WETH9.json');

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
    string memory path = string.concat(root, '/vendor/SwapRouter.json');
    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));
    bytes memory args = abi.encode(v3factory, WETH9);

    assembly {
      v3Router := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(v3Router)) {
        revert(0, 0)
      }
    }
  }

  function deployNFTDesLib() public returns (address nftMangerLib) {
    bytes memory bytecode = vm.getCode('vendor/NFTDescriptor.json');
    // vm.deployCodeTo('/vendor/NFTDescriptor.json');

    // make it deterministic
    // deploy from a new account with nonce 0
    // 0x16e82ed360012b497c0453d9010dcdda780593e6
    address deployer = address(uint160(uint256(keccak256(abi.encode('nft lib deployer')))));
    vm.prank(deployer);
    assembly {
      nftMangerLib := create(0, add(bytecode, 0x20), mload(bytecode))
      if iszero(extcodesize(nftMangerLib)) {
        revert(0, 0)
      }
    }

    // nftMangerLib must be 0x2909cD505113E0b462C49dc8cF329b56ff2d193d here
  }

  function deployNFTPositionDescriptor(
    address WETH9,
    string memory nativeCurrencyLabel
  ) public returns (address tokenDescriptor) {
    deployNFTDesLib();
    if (bytes(nativeCurrencyLabel).length > 31) {
      revert('label too long');
    }

    bytes32 label;
    assembly {
      label := mload(add(nativeCurrencyLabel, 32))
    }

    bytes memory bytecode = vm.getCode('vendor/NonfungibleTokenPositionDescriptor.json');
    bytes memory args = abi.encode(WETH9, label);

    assembly {
      tokenDescriptor := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(tokenDescriptor)) {
        revert(0, 0)
      }
    }
    // tokenDescriptor = address(new NonfungibleTokenPositionDescriptor(WETH9, label));
  }

  function deployPosManager(address factory, address WETH9, address tokenDes) public returns (address posManager) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(root, '/vendor/NonfungibleTokenPositionDescriptor.json');
    bytes memory bytecode = abi.decode(stdJson.parseRaw(vm.readFile(path), '.bytecode'), (bytes));
    bytes memory args = abi.encode(factory, WETH9, tokenDes);

    assembly {
      posManager := create(0, add(bytecode, 0x20), add(mload(bytecode), mload(args)))
      if iszero(extcodesize(posManager)) {
        revert(0, 0)
      }
    }
  }
}
