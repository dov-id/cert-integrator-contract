// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/IFeedbackRegistry.sol";
import "./interfaces/ICertIntegrator.sol";
import "./libs/SMTVerifier.sol";
import "./libs/RingSignature.sol";

/**
 *  @notice The Feedback registry contract
 *
 *  The FeedbackRegistry contract is the main contract in the Dov-Id system. It will provide the logic
 *  for adding and storing the course participants’ feedbacks, where the feedback is an IPFS hash that
 *  routes us to the user’s feedback payload on IPFS. Also, it is responsible for validating the ZKP
 *  of NFT owning.
 *
 *  Requirements:
 *
 *  - The contract must receive information about the courses and their participants from the
 *    CertIntegrator contract.
 *
 *  - The ability to add feedback by a user for a specific course with a provided ZKP of NFT owning.
 *    The proof must be validated.
 *
 *  - The ability to retrieve feedbacks with a pagination.
 *
 *  Note:
 *  dev team faced with a zkSnark proof generation problems.
 *
 *  The contract will verify only direct user’s ECDSA signature and the Sparse Merkle Tree proof (SMTP)
 *  that the user exists in a participants merkle tree, which root is stored on the CertIntegrator contract.
 *  So there will no any anonymity on the Beta version.
 */
contract FeedbackRegistry is IFeedbackRegistry {
    using RingSignature for bytes;
    using SMTVerifier for bytes32;
    using Paginator for string[];

    // course name => feedbacks (ipfs)
    mapping(bytes => string[]) public contractFeedbacks; //temporary feedback is string, while getting in what format to store ipfs hash

    // courses name => existence (to prevent iterating through all `_courses` array in order to avoid duplicates)
    mapping(bytes => bool) internal _isAddedCourse;
    // courses to have ability to retrieve all feebacks in back end service
    bytes[] internal _courses;
    address internal _certIntegrator;

    constructor(address certIntegrator_) {
        _certIntegrator = certIntegrator_;
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    // bytes courseName, bytes ringSignature, address[] participants, bytes[][] addressesMTP
    function addFeedback(
        bytes memory course_,
        //ring signature parts
        bytes32 i_,
        bytes32[] memory c_,
        bytes32[] memory r_,
        bytes[] memory publicKeys_,
        //merkle tree proofs parts
        bytes32[][] memory merkleTreeProofs_,
        bytes32[] memory keys_,
        bytes32[] memory values_,
        string memory ipfsHash_
    ) external {
        require(
            _verifySignature(bytes(ipfsHash_), i_, c_, r_, publicKeys_) == true,
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
        if (!_isAddedCourse[course_]) {
            _courses.push(course_);
        }
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getFeedbacks(
        bytes memory course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        //Deal with type for storing ipfs hash and then finish this getter
        // return contractFeedbacks[course_].part(offset_, limit_);
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getAllFeedbacks()
        external
        view
        returns (bytes[] memory courses_, string[][] memory feedbacks_)
    {
        uint256 coursesLength_ = _courses.length;

        courses_ = new bytes[](coursesLength_);
        feedbacks_ = new string[][](coursesLength_);

        for (uint256 i = 0; i < coursesLength_; i++) {
            bytes memory course_ = _courses[i];
            courses_[i] = course_;
            feedbacks_[i] = contractFeedbacks[course_];
        }
    }

    /**
     *  @dev Verifies Signature.
     *
     *  @param message_ signature message
     *  @param i_ signature key image
     *  @param c_ signature scalar C
     *  @param r_ scalars scalar R
     *  @param publicKeys_ public keys for signature verification
     *  @return true if the signature is valid
     */
    function _verifySignature(
        bytes memory message_,
        bytes32 i_,
        bytes32[] memory c_,
        bytes32[] memory r_,
        bytes[] memory publicKeys_
    ) internal pure returns (bool) {
        return
            message_.verify(
                uint256(i_),
                _bytes32ArrayToUint256Array(c_),
                _bytes32ArrayToUint256Array(r_),
                publicKeys_
            );
    }

    /**
     *  @dev Converts bytes32 array to uint256 array.
     *
     *  @param data_ bytes32 array to convert into uint256 array
     *  @return uint256[] with converted values from `data_`
     */
    function _bytes32ArrayToUint256Array(
        bytes32[] memory data_
    ) internal pure returns (uint256[] memory) {
        uint256 length_ = data_.length;

        uint256[] memory result = new uint256[](length_);
        for (uint256 i = 0; i < length_; i++) {
            result[i] = uint256(data_[i]);
        }

        return result;
    }
}
