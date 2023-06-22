// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract VerifierMock {
    function getLastData(bytes memory) public pure {
        revert("getLastData: reverts");
    }

    function mintToken(address, string memory) public pure {
        revert("mintToken: reverts");
    }
}
