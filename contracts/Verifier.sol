// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IVerifier.sol";
import "./libs/SMTVerifier.sol";

/**
 *  @notice The Verifier contract
 *
 *  ADD SOME DOCS HERE
 */
contract Verifier is IVerifier {
    using ECDSA for bytes32;
    using SMTVerifier for bytes32;

    address internal _integrator;

    constructor(address integrator_) {
        _integrator = integrator_;
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
        bytes32 ipfsHash_,
        string memory tokenUri_
    ) external returns (uint256) {
        require(_verifySignature(ipfsHash_, signature_) == true, "Verifier: wrong signature");

        (bool success_, bytes memory data_) = _integrator.call(
            abi.encodeWithSignature("getLastData(bytes)", abi.encodePacked(course_))
        );

        require(success_, "Verifier: failed to get last data");

        Data memory courseData_ = abi.decode(data_, (Data));

        require(
            courseData_.root.verifyProof(key_, value_, merkletreeProof_) == true,
            "Verifier: wrong merkle tree verification"
        );

        (success_, data_) = course_.call(
            abi.encodeWithSignature("mintToken(address,string)", msg.sender, tokenUri_)
        );

        require(success_, "Verifier: failed to mint token");

        return uint256(bytes32(data_));
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
