// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CertIntegrator is Ownable {
    struct Data { 
        bytes32 Root;
        uint256 Block;
        bytes32[] Roots;
    }

    uint private rootsAmount;
    mapping(bytes32 => Data) private contractData;

    constructor(uint256 _rootsAmount) {
        rootsAmount = _rootsAmount;
    }

    function updateCourseState (bytes32[] memory courses, bytes32[] memory states) external onlyOwner {
        uint coursesLength = courses.length;

        require(coursesLength == states.length, "updateCourseState: courses and states arrays must be the same size");

        for (uint i = 0; i < coursesLength; i++) {
            Data memory oldData = contractData[courses[i]];
            bytes32[] memory roots = handleRoots(states[i], oldData.Root, oldData.Roots); 
            
            contractData[courses[i]] = Data(states[i], block.number, roots);
        }
    }

    function handleRoots(bytes32 newRoot, bytes32 oldRoot, bytes32[] memory roots) private view returns (bytes32[] memory) {
        require(newRoot != oldRoot, "handleRoots: new root must be different");
        
        uint256 rootsLength = roots.length;
        bytes32 root = oldRoot;
        bytes32[] memory newRoots = new bytes32[](rootsAmount);

        for(uint i = 0; i < rootsAmount; i++) {
            newRoots[i] = root;

            if (rootsLength == 0 || rootsLength < i) {
                break;
            }

            root = roots[i];
        }

        return newRoots;
    }

    function getContractData(bytes32 course) public view returns (Data memory) {
        return contractData[course];
    }
}
