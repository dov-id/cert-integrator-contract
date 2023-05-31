// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICertIntegrator {
    // Structure to store contract data, such as
    // merkle tree root and corresponding blocknumber
    struct Data {
        uint256 blockNumber;
        bytes root;
    }

    function getData(bytes memory course_) external view returns (Data[] memory);

    function getLastData(bytes memory course_) external view returns (Data memory);

    function getDataLength(bytes memory course_) external view returns (uint256);
}
