// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IFeedbackRegistry {
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
    function addFeedback(
        bytes memory course_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        bytes32 ipfsHash_
    ) external;

    /**
     *  @dev Returns paginated feedbacks for the course.
     *
     *  @notice This function takes some params and returns paginated
     *  feedbacks ipfs hashes for specified course name.
     *
     *  @param course_ the course name
     *  @param offset_ the amount of feedbacks to offset
     *  @param limit_ the maximum feedbacks amount to return
     */
    function getFeedbacks(
        bytes memory course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory);
}
