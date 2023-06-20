// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";

contract TokenContract is ITokenContract, ERC721EnumerableUpgradeable {
    ITokenFactory public override tokenFactory;

    uint256 internal _tokenId;

    mapping(string => bool) public override existingTokenURIs;

    mapping(address => bool) private _localAdmins;
    mapping(uint256 => string) internal _tokenURIs;

    modifier onlyAdmin() {
        require(_localAdmins[msg.sender], "TokenContract: Only admin can call this function.");
        _;
    }

    function __TokenContract_init(
        TokenContractInitParams calldata initParams_
    ) external override initializer {
        __ERC721_init(initParams_.tokenName, initParams_.tokenSymbol);

        tokenFactory = ITokenFactory(initParams_.tokenFactoryAddr);

        _localAdmins[initParams_.admin] = true;
    }

    function setNewAdmin(address admin) external onlyAdmin {
        _localAdmins[admin] = true;
    }

    function deleteAdmin(address admin) external onlyAdmin {
        delete _localAdmins[admin];
    }

    function burn(uint256 tokenId) external onlyAdmin {
        delete _tokenURIs[tokenId];
        _burn(tokenId);
    }

    function mintToken(address to, string memory tokenURI_) external onlyAdmin returns (uint256) {
        uint256 currentTokenId_ = _tokenId++;
        _mintToken(to, currentTokenId_, tokenURI_);
        emit SuccessfullyMinted(msg.sender, currentTokenId_, tokenURI_);
        return currentTokenId_;
    }

    function getUserTokenIDs(
        address userAddr_
    ) external view override returns (uint256[] memory tokenIDs_) {
        uint256 _tokensCount = balanceOf(userAddr_);

        tokenIDs_ = new uint256[](_tokensCount);

        for (uint256 i; i < _tokensCount; i++) {
            tokenIDs_[i] = tokenOfOwnerByIndex(userAddr_, i);
        }
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "TokenContract: URI query for nonexistent token.");

        string memory baseURI_ = _baseURI();

        return
            bytes(baseURI_).length > 0
                ? string(abi.encodePacked(baseURI_, _tokenURIs[tokenId_]))
                : "";
    }

    function _mintToken(address to, uint256 mintTokenId_, string memory tokenURI_) internal {
        _mint(to, mintTokenId_);
        _tokenURIs[mintTokenId_] = tokenURI_;
        existingTokenURIs[tokenURI_] = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenFactory.baseTokenContractsURI();
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        if (!_localAdmins[spender]) {
            revert("TokenContract: Only admin can transfer token");
        }
        return true;
    }
}
