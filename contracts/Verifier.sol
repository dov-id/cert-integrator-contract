// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IVerifier.sol";
import "./interfaces/ICertIntegrator.sol";
import "./interfaces/IPoseidonHash.sol";
import "./interfaces/ITokenContract.sol";
import "./libs/SMTVerifier.sol";

/**
 *  @notice The Verifier contract
 *
 *  ADD SOME DOCS HERE
 */
contract Verifier is IVerifier {
    using ECDSA for bytes32;
    using SMTVerifier for bytes32;

    address internal _certIntegrator;

    IPoseidonHash internal _poseidon2Hash;
    IPoseidonHash internal _poseidon3Hash;

    constructor(address certIntegrator_, address poseidon2Hash_, address poseidon3Hash_) {
        _certIntegrator = certIntegrator_;
        _poseidon2Hash = IPoseidonHash(poseidon2Hash_);
        _poseidon3Hash = IPoseidonHash(poseidon3Hash_);
    }

    /**
     * @inheritdoc IVerifier
     */
    function verifyContract(
        address course_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        bytes32 ipfsHash_
    ) external returns (uint256) {
        require(_verifySignature(ipfsHash_, signature_) == true, "Verifier: wrong signature");

        ICertIntegrator.Data memory courseData_ = ICertIntegrator(_certIntegrator).getLastData(
            _addressToBytes(course_)
        );

        require(
            courseData_.root.verifyProof(
                key_,
                value_,
                merkletreeProof_,
                _poseidon2Hash,
                _poseidon3Hash
            ) == true,
            "Verifier: wrong merkle tree verification"
        );

        // TODO: think about retrieving token uri from existing one
        // to save the same certificate

        return ITokenContract(course_).mintToken(msg.sender, "TOKEN.URI");
    }

    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     *  @dev Verifies ECDSA signature.
     *
     *  @param data_ signature message
     *  @param signature_ the ecdsa signature itself
     *  @return true if the signature has corresponding data and signed by sender
     */
    function _verifySignature(
        bytes32 data_,
        bytes memory signature_
    ) internal view returns (bool) {
        return data_.toEthSignedMessageHash().recover(signature_) == msg.sender;
    }
}
