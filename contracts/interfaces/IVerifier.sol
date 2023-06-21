// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IVerifier {
    /**
     *  @dev Adds the feedback to the course.
     *
     *  @notice This function takes some params, then verifies signature, merkle
     *  tree proof and only if nothing wrong stores feedback in storage
     *
     *  @param course_ the course name
     *  @param signature_ the ecdsa signature that signed ipfs hash from msg.sender
     *  @param merkletreeProof_ the proof generated from merkle tree for specified course and user
     *  @param key_ the key to verify proof in sparse merkle tree
     *  @param value_ the value to verify proof in sparse merkle tree
     *  @param ipfsHash_ the hash from ipfs that stores feedback content
     */
    function verifyContract(
        address course_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        bytes32 ipfsHash_
    ) external returns (uint256);
}
