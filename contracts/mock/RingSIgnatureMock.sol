// SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.5.3 <0.9.0;
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../libs/RingSignature.sol";

contract RingSignatureMock {
    using RingSignature for bytes;

    function verifyRingSignature(
        bytes memory message,
        uint256 i,
        uint256[] memory c,
        uint256[] memory r,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_
    ) public pure returns (bool) {
        return message.verify(i, c, r, publicKeysX_, publicKeysY_);
    }
}
