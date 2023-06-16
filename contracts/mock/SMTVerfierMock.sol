// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "../interfaces/IPoseidonHash.sol";
import "../libs/SMTVerifier.sol";

contract SMTVerifierMock {
    using SMTVerifier for bytes32;

    function verify(
        bytes32 root_,
        bytes32 key_,
        bytes32 value_,
        bytes32[] memory merkletreeProof_,
        address poseidon2Hash_,
        address poseidon3Hash_
    ) external pure returns (bool) {
        return
            root_.verifyProof(
                key_,
                value_,
                merkletreeProof_,
                IPoseidonHash(poseidon2Hash_),
                IPoseidonHash(poseidon3Hash_)
            );
    }
}
