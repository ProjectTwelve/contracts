// SPDX-License-Identifier: GPL3.0-or-later
pragma solidity 0.8.19;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {TokenIdDecoder} from "src/TokenIdDecoder.sol";
import {IP12CommunityBadge} from "src/interfaces/IP12CommunityBadge.sol";
import {LibString} from "solady/utils/LibString.sol";

/**
 * @dev p12 badge has five rarity, they are orange, purple, blue, green, white
 * @dev for gas efficiency, we would encode the rarity in tokenId.
 * @dev we place tokenId in the following ways:
 * @dev uint200 for reserve, uint8 for rarity, uint16 for variety, uint40 for increment id
 */

contract P12CommunityBadge is IP12CommunityBadge, ERC721, Ownable {
    string private _name;
    string private _symbol;
    string public baseUri;
    mapping(address => bool) private _minters;
    mapping(bytes32 typeKey => uint256) private _indexes;

    constructor(address owner_, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        /* _transfer ownership to owner_ */
        _setOwner(owner_);
    }

    /**
     * @notice minter mint a badge with specific rarity to a user
     * @param user user address
     * @param rarity rarity of nft
     * @param variety variety of this rarity
     */
    function mint(address user, uint256 rarity, uint256 variety) external onlyMinter {
        bytes32 typeKey = _computeTypeKey(rarity, variety);
        uint256 tokenId = TokenIdDecoder.encodeTokenId(rarity, variety, _indexes[typeKey]++);
        _mint(user, tokenId);
    }

    function setMinter(address minter, bool valid) external onlyOwner {
        _minters[minter] = valid;

        emit MinterSet(minter, valid);
    }

    function setBaseUri(string calldata baseuri_) external onlyOwner {
        baseUri = baseuri_;

        emit BaseUriSet(baseuri_);
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

    /**
     * @param rarity rarity of nft
     * @param variety of this rarity
     * @return bytes32 key of the rarity + variety
     */
    function _computeTypeKey(uint256 rarity, uint256 variety) internal pure returns (bytes32) {
        return keccak256(abi.encode(rarity, variety));
    }

    function _checkMinter() internal view {
        if (!_minters[msg.sender]) {
            revert NotMinter();
        }
    }

    modifier onlyMinter() {
        _checkMinter();
        _;
    }
}
