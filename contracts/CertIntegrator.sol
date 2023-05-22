// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CertIntegrator is Ownable {
    // Contains information about root and corresponding block for it
    struct Info {
        bytes32 Root;
        uint256 Block;
    }

    // 'Queue' structure that stores queue itself and its length
    // that is also used for iterating through queu
    struct Data {
        uint256 length;
        mapping(uint256 => Info) queue;
    }

    // Size limitation for roots and blocks
    uint256 private _rootsAmount;

    // Mapping course name to its data
    mapping(bytes32 => Data) private _contractData;

    /**
     * @dev Initializes the contract last roots amount to store in case to avoid
     * collision if some root was replaced by backend service.
     */
    constructor(uint256 rootsAmount_) {
        _rootsAmount = rootsAmount_;
    }

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
        bytes32[] memory courses,
        bytes32[] memory states
    ) external onlyOwner {
        uint coursesLength = courses.length;

        require(
            coursesLength == states.length,
            "updateCourseState: courses and states arrays must be the same size"
        );

        for (uint i = 0; i < coursesLength; i++) {
            push(Info(states[i], block.number), courses[i]);

            removeLast(courses[i]);
        }
    }

    /**
     * @dev Returns maximum amount of roots that can be stored.
     */
    function getRootsAmount() public view returns (uint256) {
        return _rootsAmount;
    }

    /**
     * @dev Returns the most up to date block from the queue for
     * correspondig course.
     *
     * Requirements:
     *
     * - queue musn't be empty.
     *
     */
    function getLastBlock(bytes32 course_) public view returns (uint256) {
        Data storage data = _contractData[course_];

        require(data.length != 0, "getLastBlock: empty queue");

        return data.queue[data.length - 1].Block;
    }

    /**
     * @dev Returns the most up to date root from the queue for
     * correspondig course.
     *
     * Requirements:
     *
     * - queue musn't be empty.
     *
     */
    function getLastRoot(bytes32 course_) public view returns (bytes32) {
        Data storage data = _contractData[course_];

        require(data.length != 0, "getLastRoot: empty queue");

        return data.queue[data.length - 1].Root;
    }

    /**
     * @dev Pushes new course information
     *
     * Course information(root and block) added in the queue
     * for correspondig course name and the increases length
     * of queue for it.
     *
     */
    function push(Info memory info_, bytes32 course_) private {
        _contractData[course_].queue[_contractData[course_].length] = info_;
        _contractData[course_].length += 1;
    }

    /**
     * @dev Remove last element and fix queue
     *
     * Removes the last elemnt from the queue for the
     * corresponding course in case if its length is more
     * than 1 or higher then maximum amoun of roots.
     * Then fixes the queue to have the 'oldest' element
     * at `0` position and to keep its size up to maximum
     * permitted amount.
     * It is assumed that for a given function queue size
     * can be bigger than maximum to 1 element.
     *
     * Requirements:
     *
     * - queue musn't be empty.
     *
     */
    function removeLast(bytes32 course_) private {
        uint256 length = _contractData[course_].length;

        if (length <= 1 || length <= _rootsAmount) {
            return;
        }

        for (uint256 i = 1; i < length; i++) {
            _contractData[course_].queue[i - 1] = _contractData[course_].queue[i];
        }

        length -= 1;
        delete _contractData[course_].queue[length];

        _contractData[course_].length = length;
    }
}
