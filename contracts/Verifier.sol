// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IVerifier.sol";
import "./libs/SMTVerifier.sol";

/**
 *  @notice The Verifier contract
 *
 *  1. When we have some token in main chain, but at the same time interact with another chains,
 *  sometimes there is a need to operate data directly from one of these chains.
 *
 *  2. This contract solves such problem, by verifying that user definitely owns such token in
 *  main chain and minting token with the same uri.
 *
 *  3. Verification takes part according to such flow:
 *      a. Our contract verifies signature
 *      b. It makes call to integrator contract in order to get last root with block that was
 *         published there. Then using sparse merkle tree proof, key and value verifies proof
 *         with help of SMTVerifier lib
 *      c. If everything was processed without errors verifier contract will make a call to
 *         the contract address to mint new token in side-chain.
 *
 *  4. Note:
 *      a. As signature now we process ECDSA signature from function caller
 *      b. In ECDSA signature temporary must be signed `key_` parameter
 *      c. As merkle tree proof contract waits Sparse Merkle Tree Proof. During testing was used
 *         proofs from such [realization](https://github.com/iden3/go-merkletree-sql)
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
        address contract_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        string memory tokenUri_
    ) external returns (uint256) {
        require(_verifySignature(key_, signature_) == true, "Verifier: wrong signature");

        (bool success_, bytes memory data_) = _integrator.call(
            abi.encodeWithSignature("getLastData(bytes)", abi.encodePacked(contract_))
        );

        require(success_, "Verifier: failed to get last data");

        Data memory courseData_ = abi.decode(data_, (Data));

        require(
            courseData_.root.verifyProof(key_, value_, merkletreeProof_) == true,
            "Verifier: wrong merkle tree verification"
        );

        (success_, data_) = contract_.call(
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
