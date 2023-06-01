// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICertIntegrator.sol";

contract CertIntegrator is Ownable, ICertIntegrator {
    // Mapping course name to its data
    mapping(bytes => Data[]) public contractData;

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
        bytes[] memory courses_,
        bytes[] memory states_
    ) external onlyOwner {
        uint256 coursesLength_ = courses_.length;

        require(
            coursesLength_ == states_.length,
            "CertIntegrator: courses and states arrays must be the same size"
        );

        for (uint256 i = 0; i < coursesLength_; i++) {
            Data memory newData = Data(block.number, states_[i]);
            contractData[courses_[i]].push(newData);
        }
    }

    /**
     * @dev Retrieves info by course name.
     */
    function getData(bytes memory course_) external view returns (Data[] memory) {
        return contractData[course_];
    }

    /**
     * @dev Retrieves last info by course name.
     */
    function getLastData(bytes memory course_) external view returns (Data memory) {
        uint256 length = contractData[course_].length;
        require(length > 0, "CertIntegrator: course info is empty");
        return contractData[course_][length - 1];
    }

    /**
     * @dev Retrieves info length by course name.
     */
    function getDataLength(bytes memory course_) external view returns (uint256) {
        return contractData[course_].length;
    }
}
