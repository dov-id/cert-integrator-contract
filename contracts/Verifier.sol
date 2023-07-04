// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./interfaces/IVerifier.sol";
import "./libs/SMTVerifier.sol";
import "./libs/RingSignature.sol";

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
 *      a. As signature now we process ring signature
 *      b. As merkle tree proof contract waits Sparse Merkle Tree Proof. During testing was used
 *         proofs from such [realization](https://github.com/iden3/go-merkletree-sql)
 */
contract Verifier is IVerifier {
    using RingSignature for bytes;
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
        //ring signature parts
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_,
        //merkle tree proofs parts
        bytes32[][] memory merkleTreeProofs_,
        bytes32[] memory keys_,
        bytes32[] memory values_,
        string memory tokenUri_
    ) external returns (uint256) {
        require(
            _verifySignature(bytes(tokenUri_), i_, c_, r_, publicKeysX_, publicKeysY_) == true,
            "Verifier: wrong signature"
        );

        (bool success_, bytes memory data_) = _integrator.call(
            abi.encodeWithSignature("getLastData(bytes)", abi.encodePacked(contract_))
        );

        require(success_, "Verifier: failed to get last data");

        Data memory courseData_ = abi.decode(data_, (Data));

        for (uint k = 0; k < merkleTreeProofs_.length; k++) {
            require(
                courseData_.root.verifyProof(keys_[k], values_[k], merkleTreeProofs_[k]) == true,
                "Verifier: wrong merkle tree verification"
            );
        }

        (success_, data_) = contract_.call(
            abi.encodeWithSignature("mintToken(address,string)", msg.sender, tokenUri_)
        );

        require(success_, "Verifier: failed to mint token");

        return uint256(bytes32(data_));
    }

    /**
     *  @dev Verifies Ring Signature.
     *
     *  @param message_ signature message
     *  @param i_ signature key image
     *  @param c_ signature scalar C
     *  @param r_ scalars scalar R
     *  @param publicKeysX_ x coordinates of public keys for signature verification
     *  @param publicKeysY_ y coordinates of public keys for signature verification
     *  @return true if the signature is valid
     */
    function _verifySignature(
        bytes memory message_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_
    ) internal pure returns (bool) {
        return message_.verify(i_, c_, r_, publicKeysX_, publicKeysY_);
    }
}
