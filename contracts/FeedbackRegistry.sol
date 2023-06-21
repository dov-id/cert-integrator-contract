// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/IFeedbackRegistry.sol";
import "./interfaces/ICertIntegrator.sol";
import "./libs/SMTVerifier.sol";

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
    using ECDSA for bytes32;
    using SMTVerifier for bytes32;
    using Paginator for bytes32[];

    // course name => feedbacks (ipfs)
    mapping(bytes => bytes32[]) public contractFeedbacks;

    address internal _certIntegrator;

    constructor(address certIntegrator_) {
        _certIntegrator = certIntegrator_;
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function addFeedback(
        bytes memory course_,
        bytes memory signature_,
        bytes32[] memory merkletreeProof_,
        bytes32 key_,
        bytes32 value_,
        bytes32 ipfsHash_
    ) external {
        require(
            _verifySignature(ipfsHash_, signature_) == true,
            "FeedbackRegistry: wrong signature"
        );

        ICertIntegrator.Data memory courseData_ = ICertIntegrator(_certIntegrator).getLastData(
            course_
        );

        require(
            courseData_.root.verifyProof(key_, value_, merkletreeProof_) == true,
            "FeedbackRegistry: wrong merkle tree verification"
        );

        contractFeedbacks[course_].push(ipfsHash_);
    }

    /**
     * @inheritdoc IFeedbackRegistry
     */
    function getFeedbacks(
        bytes memory course_,
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        return contractFeedbacks[course_].part(offset_, limit_);
    }

    /**
     *  @dev Verifies ECDSA signature.
     *
     *  @param data_ signature message
     *  @param signature_ the ecdsa signature itself
     *  @return true if the signature has corresponding data and signed by sender
     */
    function _verifySignature(
        bytes32 data_,
        bytes memory signature_
    ) internal view returns (bool) {
        return data_.toEthSignedMessageHash().recover(signature_) == msg.sender;
    }
}
