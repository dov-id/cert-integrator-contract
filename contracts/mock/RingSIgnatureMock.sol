// SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.5.3 <0.9.0;
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/RingSignature.sol";

contract RingSignatureMock {
    using RingSignature for bytes;

    function verifyRingSignature(
        bytes memory message,
        bytes32 i,
        bytes32[] memory c,
        bytes32[] memory r,
        bytes[] memory publicKeys_
    ) public pure returns (bool) {
        uint256[] memory C = new uint256[](c.length);
        for (uint256 k = 0; k < c.length; k++) {
            C[k] = uint256(c[k]);
        }

        uint256[] memory R = new uint256[](r.length);
        for (uint256 k = 0; k < c.length; k++) {
            R[k] = uint256(r[k]);
        }

        return message.verify(uint256(i), C, R, publicKeys_);
    }
}
