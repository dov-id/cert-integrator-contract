// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface IVerifier {
    /**
     * Structure that stores contract data:
     * merkle tree root and corresponding block number
     */
    struct Data {
        uint256 blockNumber;
        bytes32 root;
    }

    /**
     *  @dev New docs
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
     *  @param tokenUri_ the uri of token to mint in side-chain
     */
    function verifyContract(
        address course_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        bytes32 ipfsHash_,
        string memory tokenUri_
    ) external returns (uint256);
}
