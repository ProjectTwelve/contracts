// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {IStarNFT} from "src/bridge/interfaces/IStarNFT.sol";

contract StarNFT is ERC721, IStarNFT {
    mapping(uint256 => uint256) internal _cid;

    function mint(address user, uint256 tokenId, uint256 cid_) public {
        _mint(user, tokenId);
        _cid[tokenId] = cid_;
    }

    function cid(uint256 tokenId) public view override returns (uint256) {
        return _cid[tokenId];
    }

    function name() public pure override returns (string memory) {
        return "Star NFT";
    }

    function symbol() public pure override returns (string memory) {
        return "SNFT";
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}
