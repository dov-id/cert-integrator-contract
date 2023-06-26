// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICertIntegrator.sol";

/**
 *  @notice The Cert integrator contract
 *
 *  1. While the FeedbackRegistry contracts will be deployed on multiple chains, another contracts
 *  will only be present on its main chain. This contract is a Solidity contract that solves
 *  the previous problem.
 *
 *  2. This contract will be deployed on the supported chains, and its purpose is to store and
 *  provide the ability to update data about courses and their participants from the chains.
 *
 *  3.This data is the root of the Sparse Merkle tree that contains course participants. Whenever
 *  a certificate is issued or a new course is created, the CertIntegration service will
 *  update the data. This way, every instance of FeedbackRegistry on different chains will have
 *  the latest and most up-to-date data available.
 *
 *  4. Requirements:
 *
 *      - The ability to update the state for a specific course. It is only for a contract owner.
 *
 *      - The contract must store all roots, to avoid collision when the user generates a ZKP for
 *        a specific merkle root, but after several seconds this root is replaced by the CertIntegrator
 *        service. Also, the contract should bind up every state to the block number. It will provide
 *        an ability for external services to set some interval of blocks in which they will consider
 *        this state valid.
 */
contract CertIntegrator is Ownable, ICertIntegrator {
    // course name => data (root+block)
    mapping(bytes => Data[]) public contractData;

    /**
     * @inheritdoc ICertIntegrator
     */
    function updateCourseState(
        bytes[] memory courses_,
        bytes32[] memory states_
    ) external onlyOwner {
        uint256 coursesLength_ = courses_.length;

        require(
            coursesLength_ == states_.length,
            "CertIntegrator: courses and states arrays must be the same size"
        );

        for (uint256 i = 0; i < coursesLength_; i++) {
            Data memory newData_ = Data(block.number, states_[i]);
            contractData[courses_[i]].push(newData_);
        }
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getData(bytes memory course_) external view returns (Data[] memory) {
        return contractData[course_];
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getLastData(bytes memory course_) external view returns (Data memory) {
        uint256 length_ = contractData[course_].length;

        require(length_ > 0, "CertIntegrator: course info is empty");

        return contractData[course_][length_ - 1];
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getDataLength(bytes memory course_) external view returns (uint256) {
        return contractData[course_].length;
    }
}
