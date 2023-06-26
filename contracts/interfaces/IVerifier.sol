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
     *  @dev Function to mint token in side-chain
     *
     *  @notice This function takes some params, then verifies signature, merkle
     *  tree proof and then mint new token.
     *
     *  @param contract_ the contract address to retrieve last root for and to mint new token from
     *  @param signature_ the ecdsa signature that signed `key_` parameter from msg.sender
     *  @param merkletreeProof_ the proof generated from merkle tree for specified course and user
     *  @param key_ the key to verify proof in sparse merkle tree
     *  @param value_ the value to verify proof in sparse merkle tree
     *  @param tokenUri_ the uri of token to mint in side-chain
     *  @return id of the newly minted token
     */
    function verifyContract(
        address contract_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        string memory tokenUri_
    ) external returns (uint256);
}
