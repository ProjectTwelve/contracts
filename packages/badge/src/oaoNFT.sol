// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {EIP712} from "solady/utils/EIP712.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

// one and only nft
contract oaoNFT is ERC721, Ownable, EIP712 {
    string private _name;
    string private _symbol;
    string public baseUri;
    bytes32 typeHash = keccak256("WhitelistMint(address user,uint256 deadline)");
    mapping(address => bool) _signers;

    constructor(address owner_, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        /* _transfer ownership to owner_ */
        _setOwner(owner_);
    }

    function whitelistMint(uint256 deadline, bytes32 r, bytes32 vs) public {
        bytes32 digest = _hashTypedData(keccak256(abi.encode(typeHash, msg.sender, deadline)));

        address signer = ECDSA.recover(digest, r, vs);
        require(_signers[signer], "invalid signer");

        uint256 tokenId = uint256(keccak256(abi.encode(msg.sender)));
        require(!_exists(tokenId), "already minted");

        _mint(msg.sender, tokenId);
    }

    function checkIfMinted(address user) public view returns (bool) {
        uint256 tokenId = uint256(keccak256(abi.encode(user)));
        return _exists(tokenId);
    }

    function setBaseUri(string calldata uri_) external {
        baseUri = uri_;
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
