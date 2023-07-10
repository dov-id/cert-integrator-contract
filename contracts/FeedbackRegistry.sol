// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/IFeedbackRegistry.sol";
import "./interfaces/ICertIntegrator.sol";
import "./libs/SMTVerifier.sol";
import "./libs/RingSignature.sol";

/**
 *  @notice The Feedback registry contract
 *
 *  1. The FeedbackRegistry contract is the main contract in the Dov-Id system. It will provide the logic
 *  for adding and storing the course participants’ feedbacks, where the feedback is an IPFS hash that
 *  routes us to the user’s feedback payload on IPFS. Also, it is responsible for validating the ZKP
 *  of NFT owning.
 *
 *  2. The course identifier - is its adddress as every course is represented by NFT contract.
 *
 *  3. Requirements:
 *
 *  - The contract must receive information about the courses and their participants from the
 *    CertIntegrator contract.
 *
 *  - The ability to add feedback by a user for a specific course with a provided ZKP of NFT owning.
 *    The proof must be validated.
 *
 *  - The ability to retrieve feedbacks with a pagination.
 *
 *  4. Note:
 *     Dev team faced with a zkSnark proof generation problems, so now
 *  contract checks that the addressesMTP root is stored in the CertIntegrator contract and that all
 *  MTPs are correct. The contract checks the ring signature as well, and if it is correct the
 *  contract adds feedback to storage.
 */
contract FeedbackRegistry is IFeedbackRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;
    using RingSignature for bytes;
    using SMTVerifier for bytes32;
    using Paginator for EnumerableSet.AddressSet;

    // course address => feedbacks (ipfs)
    mapping(address => string[]) public contractFeedbacks;

    address private _certIntegrator;

    EnumerableSet.AddressSet private _courses;

    constructor(address certIntegrator_) {
        _certIntegrator = certIntegrator_;
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function addFeedback(
        address course_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_,
        bytes32[][] memory merkleTreeProofs_,
        bytes32[] memory keys_,
        bytes32[] memory values_,
        string memory ipfsHash_
    ) external {
        require(
            _verifySignature(bytes(ipfsHash_), i_, c_, r_, publicKeysX_, publicKeysY_) == true,
            "FeedbackRegistry: wrong signature"
        );

        ICertIntegrator.Data memory courseData_ = ICertIntegrator(_certIntegrator).getLastData(
            course_
        );

        for (uint k = 0; k < merkleTreeProofs_.length; k++) {
            require(
                courseData_.root.verifyProof(keys_[k], values_[k], merkleTreeProofs_[k]) == true,
                "FeedbackRegistry: wrong merkle tree verification"
            );
        }

        contractFeedbacks[course_].push(ipfsHash_);
        _courses.add(course_);
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getFeedbacks(
        address course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory) {
        uint256 to_ = Paginator.getTo(contractFeedbacks[course_].length, offset_, limit_);

        string[] memory list_ = new string[](to_ - offset_);

        for (uint256 i = offset_; i < to_; i++) {
            list_[i - offset_] = contractFeedbacks[course_][i];
        }

        return list_;
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getAllFeedbacks(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory courses_, string[][] memory feedbacks_) {
        courses_ = _courses.part(offset_, limit_);

        uint256 coursesLength_ = courses_.length;

        feedbacks_ = new string[][](coursesLength_);

        for (uint256 i = 0; i < coursesLength_; i++) {
            feedbacks_[i] = contractFeedbacks[courses_[i]];
        }
    }

    /**
     *  @dev Verifies Ring Signature.
     *
     *  @param message_ signature message
     *  @param i_ signature key image
     *  @param c_ signature scalar C
     *  @param r_ scalars scalar R
     *  @param publicKeysX_ x coordinates of public keys for signature verification
     *  @param publicKeysY_ y coordinates of public keys for signature verification
     *  @return true if the signature is valid
     */
    function _verifySignature(
        bytes memory message_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_
    ) internal pure returns (bool) {
        return message_.verify(i_, c_, r_, publicKeysX_, publicKeysY_);
    }
}
