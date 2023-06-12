// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@dlsl/dev-modules/libs/arrays/Paginator.sol";

import "./interfaces/ICertIntegrator.sol";
import "./interfaces/IPoseidonHash.sol";

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

contract FeedbackRegistry {
    using ECDSA for bytes32;
    using Paginator for bytes32[];

    // Mapping course name to its feedbacks
    mapping(bytes => bytes32[]) public contractFeedbacks;

    // Address of CertIntegrator contract
    address internal _certIntegrator;

    IPoseidonHash internal _poseidon2Hash;
    IPoseidonHash internal _poseidon3Hash;

    constructor(address certIntegrator_, address poseidon2Hash_, address poseidon3Hash_) {
        _certIntegrator = certIntegrator_;
        _poseidon2Hash = IPoseidonHash(poseidon2Hash_);
        _poseidon3Hash = IPoseidonHash(poseidon3Hash_);
    }

    /**
     *  @dev Adds the feedback to the course.
     *
     *  @notice This function takes some params, verify signature, merkle
     *  tree proof and then stores feedback in storage
     *
     *  @param course_ the course name
     *  @param signature_ the ecdsa signature that signed ipfs hash from msg.sender
     *  @param merkletreeProof_ the proof generated from merkle tree for specified course and user
     *  @param key_ the key to verify proof in sparse merkle tree
     *  @param value_ the value to verify proof in sparse merkle tree
     *  @param ipfsHash_ the hash from ipfs that stores feedback content
     *
     */
    function addFeedback(
        bytes memory course_,
        bytes memory signature_,
        bytes[] memory merkletreeProof_,
        bytes memory key_,
        bytes memory value_,
        bytes memory ipfsHash_
    ) external {
        bytes32 ipfsHashBytes32_ = bytesToBytes32(ipfsHash_);

        require(
            verifySignature(ipfsHashBytes32_, signature_) == true,
            "FeedbackRegistry: wrong signature"
        );

        ICertIntegrator.Data memory courseData_ = ICertIntegrator(_certIntegrator).getLastData(
            course_
        );

        bytes32 root = rootFromProof(
            bytesArrToBytes32Arr(merkletreeProof_),
            bytesToBytes32(key_),
            bytesToBytes32(swapEndianness(key_)),
            bytesToBytes32(value_)
        );
        bool verified_ = bytesToBytes32(courseData_.root) == root;

        require(verified_ == true, "FeedbackRegistry: wrong merkle tree verification");

        contractFeedbacks[course_].push(ipfsHashBytes32_);
    }

    /**
     *  @dev Returns paginated feedbacks for the course.
     *
     *  @notice This function takes some params and returns paginated
     *  feedbacks ipfs hashes for specified course name.
     *
     *  @param course_ the course name
     *  @param offset_ the amount of feedbacks to offset
     *  @param limit_ the maximum feedbacks amount to return
     *
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
     *
     */
    function verifySignature(bytes32 data_, bytes memory signature_) internal view returns (bool) {
        return data_.toEthSignedMessageHash().recover(signature_) == msg.sender;
    }

    /**
     *  @dev Returns root from proof.
     *
     *  @param proof_ sparse merkle tree proof
     *  @param key_ the key to verify in smt
     *  @param swappedKey_ the key with swapped endianness (bytes order)
     *  @param value_ the value to verify in smt
     *  @return bytes32 when retrieves the root from proof with given key and value
     *
     */
    function rootFromProof(
        bytes32[] memory proof_,
        bytes32 key_,
        bytes32 swappedKey_,
        bytes32 value_
    ) internal view returns (bytes32) {
        int256 proofDepth_ = int256(proof_.length);
        int256 siblingIdx_ = proofDepth_ - 1;
        bytes32 midKey_ = newPoseidonHash3(key_, value_, bytes32(uint256(1)));
        bytes32 siblingKey_;

        for (int256 lvl = proofDepth_ - 1; lvl >= 0; lvl--) {
            if (siblingIdx_ < 0) {
                break;
            }

            siblingKey_ = proof_[uint256(siblingIdx_)];
            siblingIdx_--;

            if (testBit(swappedKey_, uint256(lvl))) {
                midKey_ = newPoseidonHash2(siblingKey_, midKey_);
            } else {
                midKey_ = newPoseidonHash2(midKey_, siblingKey_);
            }
        }

        return midKey_;
    }

    /**
     *  @dev Converts bytes to bytes32.
     *
     *  @param data_ bytes data to convert
     *  @return result_ converted bytes32 data
     *
     *  Requirements:
     *
     * - the `data_` length must be at least 32 bytes.
     *
     */
    function bytesToBytes32(bytes memory data_) internal pure returns (bytes32 result_) {
        require(data_.length >= 32, "FeedbackRegistry: input data must be at least 32 bytes");

        assembly {
            result_ := mload(add(data_, 32))
        }
    }

    /**
     *  @dev Converts bytes array to bytes32 array.
     *
     *  @param data_ bytes data array to convert
     *  @return result_ converted bytes32 data array
     *
     */
    function bytesArrToBytes32Arr(
        bytes[] memory data_
    ) internal pure returns (bytes32[] memory result_) {
        uint256 length_ = data_.length;

        result_ = new bytes32[](length_);

        for (uint256 i = 0; i < length_; ++i) {
            result_[i] = bytesToBytes32(data_[i]);
        }
    }

    /**
     *  @dev Swaps bytes order (endianness).
     *
     *  @param data_ bytes data to swap byte order
     *  @return bytes with swapped `data_` bytes order
     *
     */
    function swapEndianness(bytes memory data_) internal pure returns (bytes memory) {
        uint256 length_ = data_.length;
        bytes memory result_ = new bytes(length_);

        for (uint256 i = 0; i < length_; i++) {
            result_[length_ - 1 - i] = data_[i];
        }

        return result_;
    }

    /**
     *  @dev Tests bit.
     *
     *  @notice This function tests bit value. It takes the byte
     *  at the specified index, then shifts the bit to the right
     *  position and perform bitwise AND, then checks if the bit
     *  is set (not zero)
     *
     *  @param bitmap_ bytes array
     *  @param n_ position of bit to test
     *  @return true if bit in such postition is set (1)
     *
     */
    function testBit(bytes32 bitmap_, uint256 n_) internal pure returns (bool) {
        uint256 byteIndex_ = n_ / 8;
        uint256 bitIndex_ = n_ % 8;

        uint8 byteValue_ = uint8(bitmap_[byteIndex_]);
        uint8 mask_ = uint8(1 << bitIndex_);
        uint8 result_ = byteValue_ & mask_;

        return result_ != 0;
    }

    /**
     *  @dev Makes poseidon hash.
     *
     *  @notice This function creates poseidon hash from 2 elements.
     *
     *  @param elem1_ the first element
     *  @param elem2_ the second element
     *  @return bytes32 poseidon hash from elements
     *
     */
    function newPoseidonHash2(bytes32 elem1_, bytes32 elem2_) internal view returns (bytes32) {
        return _poseidon2Hash.poseidon([elem1_, elem2_]);
    }

    /**
     *  @dev Makes poseidon hash.
     *
     *  @notice This function creates poseidon hash from 3 elements.
     *
     *  @param elem1_ the first element
     *  @param elem2_ the second element
     *  @param elem3_ the second element
     *  @return bytes32 poseidon hash from elements
     *
     */
    function newPoseidonHash3(
        bytes32 elem1_,
        bytes32 elem2_,
        bytes32 elem3_
    ) internal view returns (bytes32) {
        return _poseidon3Hash.poseidon([elem1_, elem2_, elem3_]);
    }
}
