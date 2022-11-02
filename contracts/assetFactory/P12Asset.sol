// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import './interfaces/IP12Asset.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '../access/SafeOwnable.sol';

contract P12Asset is IP12Asset, ERC1155(''), SafeOwnable {
  /**
   * @dev contract-level metadata uri, refer to https://docs.opensea.io/docs/contract-level-metadata
   */
  string public contractURI;

  /**
   * @dev current supply, how many a id are minted not.
   */
  mapping(uint256 => uint256) public supply;

  /**
   * @dev max supply, a token id has a max supply cap
   */
  mapping(uint256 => uint256) public maxSupply;
  /**
   * @dev token id index, which will increase one by one
   */
  uint256 private idx = 0;

  // metadata uri
  mapping(uint256 => string) private _uris;

  constructor(address owner_, string memory contractURI_) SafeOwnable(owner_) {
    require(bytes(contractURI_).length != 0, 'P12Asset: empty contractURI');
    contractURI = contractURI_;
  }

  /**
   * @dev developer create an new asset
   * @param amount the new asset's totalSupply
   * @param newUri metadata uri of the asset
   * @return uint256 new asset's tokenId
   */

  function create(uint256 amount, string calldata newUri) public override onlyOwner returns (uint256) {
    // set tokenId totalSupply
    maxSupply[idx] = amount;
    // set metadata Uri
    _setUri(idx, newUri);
    // idx increment
    idx += 1;
    return idx - 1;
  }

  /**
   * @dev update token's metadata uri
   * @param id tokenId
   * @param newUri new uri
   */
  function setUri(uint256 id, string calldata newUri) public override onlyOwner {
    _setUri(id, newUri);
  }

  /**
   * See {_mint}.
   */
  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override onlyOwner {
    require(id < idx, 'P12Asset: id is not valid');
    require(amount + supply[id] <= maxSupply[id], 'P12Asset: exceed max supply');
    supply[id] += amount;
    _mint(to, id, amount, data);
  }

  /**
   * @dev return token metadata uri
   * @param id token's id
   * @return uri metadata uri
   */
  function uri(uint256 id) public view virtual override returns (string memory) {
    require(id < idx, 'P12Asset: id not exist');
    return _uris[id];
  }

  /**
   * @dev set contract-level MetaData
   * @param newContractURI new Contract-level metadata uri
   */
  function setContractURI(string calldata newContractURI) public override onlyOwner {
    require(bytes(newContractURI).length != 0, 'P12Asset: empty contractURI');
    string memory oldContractURI = contractURI;
    contractURI = newContractURI;
    emit SetContractURI(oldContractURI, contractURI);
  }

  /**
   * @dev set token metadata uri
   * @param id  token id
   * @param newUri metadata uri
   */
  function _setUri(uint256 id, string calldata newUri) private {
    require(bytes(newUri).length != 0, 'P12Asset: empty uri');
    require(id <= idx, 'P12Asset: id not exist');
    _uris[id] = newUri;
    emit SetUri(id, newUri);
  }
}
