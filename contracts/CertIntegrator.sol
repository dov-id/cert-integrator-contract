// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CertIntegrator is Ownable {
    // Mapping course name to its data (root - corresponding block)
    mapping(bytes32 => mapping(bytes32 => uint256)) public contractData;

    /**
     * @dev Updates the contract information abouts course states.
     *
     * This function takes two equal size arrays that contains courses
     * names and merkle tree roots (to identify whether the user in course).
     * Each root in the list corresponds to the course with such name.
     *
     * Requirements:
     *
     * - the `courses` and `states` arrays length must be equal.
     *
     */
    function updateCourseState(
        bytes32[] memory courses_,
        bytes32[] memory states_
    ) external onlyOwner {
        uint256 coursesLength = courses_.length;

        require(
            coursesLength == states_.length,
            "updateCourseState: courses and states arrays must be the same size"
        );

        for (uint256 i = 0; i < coursesLength; i++) {
            contractData[courses_[i]][states_[i]] = block.number;
        }
    }
}
