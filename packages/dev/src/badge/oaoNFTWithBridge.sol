// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {EIP712} from "solady/utils/EIP712.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {IBridgeReceiver} from "src/badge/interfaces/IBridgeReceiver.sol";

// one and only nft
contract oaoNFTWithBridge is ERC721, Ownable, EIP712, IBridgeReceiver {
    string private _name;
    string private _symbol;
    string public baseUri;
    bytes32 typeHash = keccak256("WhitelistMint(address user,uint256 deadline)");
    mapping(address => bool) _signers;
    uint256 immutable _dstChainId;

    constructor(address owner_, uint256 dstChainId_, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _dstChainId = dstChainId_;

        /* _transfer ownership to owner_ */
        _setOwner(owner_);
    }

    function whitelistMintAndBridge(uint256 deadline, bytes32 r, bytes32 vs) public {
        bytes32 digest = _hashTypedData(keccak256(abi.encode(typeHash, msg.sender, deadline)));

        address signer = ECDSA.recover(digest, r, vs);
        require(_signers[signer], "invalid signer");

        uint256 tokenId = uint256(keccak256(abi.encode(msg.sender)));
        require(!_exists(tokenId), "already minted");

        _mint(address(this), tokenId);

        emit SendOaoNFT(_dstChainId, tokenId, address(this), msg.sender, msg.sender);
    }

    function checkIfMinted(address user) public view returns (bool) {
        uint256 tokenId = uint256(keccak256(abi.encode(user)));
        return _exists(tokenId);
    }

    function setBaseUri(string calldata uri_) external onlyOwner {
        baseUri = uri_;
    }

    function updateSigners(address signer, bool valid) public onlyOwner {
        _signers[signer] = valid;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, LibString.toString(tokenId), ".json"));
    }

    function _domainNameAndVersion() internal pure override returns (string memory n, string memory v) {
        n = "oaoNFT";
        v = "1";
    }
}
