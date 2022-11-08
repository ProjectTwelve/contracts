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
    if (bytes(contractURI_).length == 0) revert EmptyContractURI();
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
    if (id >= idx) revert InvalidTokenId(id);
    if (amount + supply[id] > maxSupply[id]) revert MintExceedSupply(id);
    supply[id] += amount;
    _mint(to, id, amount, data);
  }

  /**
   * @dev return token metadata uri
   * @param id token's id
   * @return uri metadata uri
   */
  function uri(uint256 id) public view virtual override returns (string memory) {
    if (id >= idx) revert InvalidTokenId(id);
    return _uris[id];
  }

  /**
   * @dev set contract-level MetaData
   * @param newContractURI new Contract-level metadata uri
   */
  function setContractURI(string calldata newContractURI) public override onlyOwner {
    if (bytes(newContractURI).length == 0) revert EmptyContractURI();
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
    if (bytes(newUri).length == 0) revert EmptyURI();
    if (id > idx) revert InvalidTokenId(id);
    _uris[id] = newUri;
    emit SetUri(id, newUri);
  }
}
