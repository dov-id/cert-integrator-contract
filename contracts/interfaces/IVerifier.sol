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
     *  @param i_ the ring signature image
     *  @param c_ signature scalar C
     *  @param r_  signature scalar R
     *  @param publicKeysX_ x coordinates of public keys that took part in generating signature for its verification
     *  @param publicKeysY_ y coordinates of public keys that took part in generating signature for its verification
     *  @param merkleTreeProofs_ the proofs generated from merkle tree for specified course and users
     *  whose public keys were used to generate ring signature
     *  @param keys_ keys to verify proofs in sparse merkle tree
     *  @param values_ values to verify proofs in sparse merkle tree
     *  @param tokenUri_ the uri of token to mint in side-chain
     *  @return id of the newly minted token
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
    ) external returns (uint256);
}
