// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IFeedbackRegistry {
    /**
     *  @dev Adds the feedback to the course.
     *
     *  @notice This function takes some params, then verifies signature, merkle
     *  tree proofs and only if nothing wrong stores feedback in storage.
     *  Should be noticed:
     *      - `i_`, `c_`, `r_`, `publickKeysX_` and `publickKeysY_` are parts of Ring
     *  signature;
     *      - `merkleTreeProofs_`, `keys_` and `values_` are parts of merkle tree proofs
     *  to verify that all users that took part in ring signature are course participants.
     *
     *  @param course_ the course address
     *  @param i_ the ring signature image
     *  @param c_ signature scalar C
     *  @param r_  signature scalar R
     *  @param publicKeysX_ x coordinates of public keys that took part in generating signature for its verification
     *  @param publicKeysY_ y coordinates of public keys that took part in generating signature for its verification
     *  @param merkleTreeProofs_ the proofs generated from merkle tree for specified course and users
     *  whose public keys were used to generate ring signature
     *  @param keys_ keys to verify proofs in sparse merkle tree
     *  @param values_ values to verify proofs in sparse merkle tree
     *  @param ipfsHash_ the hash from ipfs that stores feedback content
     */
    function addFeedback(
        address course_,
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
        string memory ipfsHash_
    ) external;

    /**
     *  @dev Returns paginated feedbacks for the course.
     *
     *  @notice This function takes some params and returns paginated
     *  feedbacks ipfs hashes for specified course name.
     *
     *  @param course_ the course addrss
     *  @param offset_ the amount of feedbacks to offset
     *  @param limit_ the maximum feedbacks amount to return
     */
    function getFeedbacks(
        address course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory);

    /**
     *  @dev Function that mostly oriented to publisher-svc.
     *
     *  @notice This function returns ALL feedbacks that are stored in storage
     *  for ALL courses.
     *
     *  @param offset_ the amount of courses to offset
     *  @param limit_ the maximum courses amount to return theid feedbacks
     *  @return courses_ feedbacks_  where `courses_` is array with course identifiers and
     *  `feebacks_` is 2d array with feebacks (their ipfs hashes) for corresponding course
     *  from `courses_
     */
    function getAllFeedbacks(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory courses_, string[][] memory feedbacks_);
}
