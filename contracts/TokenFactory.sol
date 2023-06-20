// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@dlsl/dev-modules/contracts-registry/pools/proxy/ProxyBeacon.sol";
import "@dlsl/dev-modules/contracts-registry/pools/pool-factory/proxy/PublicBeaconProxy.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/ITokenFactory.sol";
import "./interfaces/ITokenContract.sol";

contract TokenFactory is ITokenFactory, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Paginator for EnumerableSet.AddressSet;

    ProxyBeacon public override tokenContractsBeacon;

    string public override baseTokenContractsURI;

    EnumerableSet.AddressSet internal _tokenContracts;

    mapping(uint256 => address) public override tokenContractByIndex;

    function __TokenFactory_init(string memory baseTokenContractsURI_) external initializer {
        __Ownable_init();
        tokenContractsBeacon = new ProxyBeacon();
        baseTokenContractsURI = baseTokenContractsURI_;
    }

    function deployTokenContract(DeployTokenContractParams calldata params_) external {
        require(
            tokenContractByIndex[params_.tokenContractId] == address(0),
            "TokenFactory: TokenContract with such id already exists."
        );

        address newTokenContract_ = address(
            new PublicBeaconProxy(address(tokenContractsBeacon), "")
        );

        ITokenContract(newTokenContract_).__TokenContract_init(
            ITokenContract.TokenContractInitParams(
                params_.tokenName,
                params_.tokenSymbol,
                address(this),
                msg.sender
            )
        );

        _tokenContracts.add(newTokenContract_);
        tokenContractByIndex[params_.tokenContractId] = newTokenContract_;

        emit TokenContractDeployed(newTokenContract_, params_);
    }

    function setNewImplementation(address newImplementation_) external onlyOwner {
        if (tokenContractsBeacon.implementation() != newImplementation_) {
            tokenContractsBeacon.upgrade(newImplementation_);
        }
    }

    function setBaseTokenContractsURI(
        string memory baseTokenContractsURI_
    ) external override onlyOwner {
        baseTokenContractsURI = baseTokenContractsURI_;

        emit BaseTokenContractsURIUpdated(baseTokenContractsURI_);
    }

    function getTokenContractsPart(
        uint256 offset_,
        uint256 limit_
    ) external view override returns (address[] memory) {
        return _tokenContracts.part(offset_, limit_);
    }

    function getTokenContractsImpl() external view override returns (address) {
        return tokenContractsBeacon.implementation();
    }

    function getTokenContractsCount() external view override returns (uint256) {
        return _tokenContracts.length();
    }
}
