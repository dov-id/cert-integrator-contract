// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface ICertIntegrator {
    /**
     * Structure to store contract data:
     * merkle tree root and corresponding block number
     */
    struct Data {
        uint256 blockNumber;
        bytes32 root;
    }

    /**
     * @dev Updates the contract information abouts course states.
     *
     * This function takes two equal size arrays that contains courses
     * addresses and merkle tree roots (to identify whether the user in course).
     * Each root in the list corresponds to the course with such name.
     *
     * @param courses_ array with course address
     * @param states_ array with course states
     *
     * Requirements:
     *
     * - the `courses_` and `states_` arrays length must be equal.
     */
    function updateCourseState(address[] memory courses_, bytes32[] memory states_) external;

    /**
     * @dev Retrieves info by course address.
     *
     * @param course_ course address to retrieve info
     * @return Data[] with all states for course
     */
    function getData(address course_) external view returns (Data[] memory);

    /**
     * @dev Retrieves last info by course address.
     *
     * @param course_ course address to retrieve info
     * @return Data with last state for course
     */
    function getLastData(address course_) external view returns (Data memory);

    /**
     * @dev Retrieves info length by course address.
     *
     * @param course_ course address to retrieve info length
     * @return uint256 amount of Data[] elements
     */
    function getDataLength(address course_) external view returns (uint256);
}
