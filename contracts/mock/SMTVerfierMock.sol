// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../libs/SMTVerifier.sol";

contract SMTVerifierMock {
    using SMTVerifier for bytes32;

    function verify(
        bytes32 root_,
        bytes32 key_,
        bytes32 value_,
        bytes32[] memory merkletreeProof_
    ) external pure returns (bool) {
        return root_.verifyProof(key_, value_, merkletreeProof_);
    }
}
