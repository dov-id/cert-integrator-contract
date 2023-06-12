// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
 * @notice The Poseidon hash contract is used to hash data with Poseidon hash function.
 */
interface IPoseidonHash {
    /**
     * @notice Function for hashing with Poseidon hash function
     * @param input an array of input value
     * @param poseidonHash a poseidon hash of input
     */
    function poseidon(bytes32[2] memory input) external pure returns (bytes32 poseidonHash);

    /**
     * @notice Function for hashing with Poseidon hash function
     * @param input an array of input value
     * @param poseidonHash a poseidon hash of input
     */
    function poseidon(bytes32[3] memory input) external pure returns (bytes32 poseidonHash);
}
