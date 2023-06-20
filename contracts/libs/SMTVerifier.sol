// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../interfaces/IPoseidonHash.sol";

/**
 *  @notice This library is needed for verifying sparse merkle tree proof, that are generated with
 *  help of [Sparse Merkle Tree](https://github.com/iden3/go-merkletree-sql) in backend service,
 *  written in Golang (to generate proof just use `GenerateProof` method from the library).
 *
 *  This realization had some uses Poseidon hashing as a main hash function. The main repo for usage
 *  can be found in [circomlibjs](https://github.com/iden3/circomlibjs). Example of its usage and
 *  linking can be found in tests for this library.
 *
 *  Gas usage for main `verifyProof` method is:
 *  Min: ???
 *  Avg: ???
 *  Max: ???
 *
 *  With this library there is no need to implement own realization for proof verifying in iden3 sparse
 *  merklee tree realization.
 */
library SMTVerifier {
    function verifyProof(
        bytes32 root_,
        bytes32 key_,
        bytes32 value_,
        bytes32[] memory proof_,
        IPoseidonHash poseidon2Hash_,
        IPoseidonHash poseidon3Hash_
    ) internal pure returns (bool) {
        return _verifyProof(root_, key_, value_, proof_, poseidon2Hash_, poseidon3Hash_);
    }

    /**
     *  @dev Verifies root from proof.
     *
     *  @notice Function takes some params and requires merkle tree proof
     *  array not to be empty to have ability to retrieve root from it. Then,
     *  it generates tree leaf from `key_`, `value_` and `1` (level in tree)
     *  with help of poseidon hashing for 3 elements (`poseidon3Hash_`). On the
     *  next step it starts processing proof elements (starting from the last
     *  element (`proof_.length - 1`)) until all are proccessed. At every
     *  iteraton it checks if the bit is set (not zero) to get kind of a path
     *  from the root to the leaf. When all elements are processed, retreieved
     *  node compared with given root to get response.
     *
     *  @param root_ merkle tree root to verify with
     *  @param key_ the key to verify in smt
     *  @param value_ the value to verify in smt
     *  @param proof_ sparse merkle tree proof
     *  @param poseidon2Hash_ poseidon hashing for 2 elements contract
     *  @param poseidon3Hash_ poseidon hashing for 3 elements contract
     *  @return true when retireved smt root from proof is equal to the given `root_`
     *
     *  Requirements:
     *
     * - the `proof_` array mustn't be empty.
     */
    function _verifyProof(
        bytes32 root_,
        bytes32 key_,
        bytes32 value_,
        bytes32[] memory proof_,
        IPoseidonHash poseidon2Hash_,
        IPoseidonHash poseidon3Hash_
    ) private pure returns (bool) {
        uint256 proofLength_ = proof_.length;

        require(proofLength_ > 0, "SMTVerifier: sparse merkle tree proof is empty");

        bytes32 midKey_ = _swapEndianness(
            _newPoseidonHash3(
                poseidon3Hash_,
                _swapEndianness(key_),
                _swapEndianness(value_),
                bytes32(uint256(1))
            )
        );
        bytes32 siblingKey_;
        for (uint256 lvl = proofLength_ - 1; ; lvl--) {
            siblingKey_ = proof_[lvl];

            if (_testBit(key_, uint256(lvl))) {
                midKey_ = _swapEndianness(
                    _newPoseidonHash2(
                        poseidon2Hash_,
                        _swapEndianness(siblingKey_),
                        _swapEndianness(midKey_)
                    )
                );
            } else {
                midKey_ = _swapEndianness(
                    _newPoseidonHash2(
                        poseidon2Hash_,
                        _swapEndianness(midKey_),
                        _swapEndianness(siblingKey_)
                    )
                );
            }

            if (lvl == 0) {
                break;
            }
        }

        return midKey_ == root_;
    }

    /**
     *  @dev Swaps bytes order (endianness).
     *
     *  @notice Function to swap bytes order, for better
     *  understanding it just makes `result[len(data)-1-i] = data[i]`
     *  for every byte in bytes array.
     *
     *  @param data_ bytes data to swap byte order
     *  @return bytes with swapped `data_` bytes order
     */
    function _swapEndianness(bytes32 data_) private pure returns (bytes32) {
        uint256 result_;

        for (uint i = 0; i < 32; i++) {
            result_ |= (255 & (uint256(data_) >> (i * 8))) << ((31 - i) * 8);
        }

        return bytes32(result_);
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
     */
    function _testBit(bytes32 bitmap_, uint256 n_) private pure returns (bool) {
        uint256 byteIndex_ = n_ >> 3;
        uint256 bitIndex_ = n_ & 7;

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
     */
    function _newPoseidonHash2(
        IPoseidonHash poseidon2Hash_,
        bytes32 elem1_,
        bytes32 elem2_
    ) private pure returns (bytes32) {
        // return PoseidonUnit2L.poseidon([elem1_, elem2_]);
        return poseidon2Hash_.poseidon([elem1_, elem2_]);
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
     */
    function _newPoseidonHash3(
        IPoseidonHash poseidon3Hash_,
        bytes32 elem1_,
        bytes32 elem2_,
        bytes32 elem3_
    ) private pure returns (bytes32) {
        return poseidon3Hash_.poseidon([elem1_, elem2_, elem3_]);
    }
}
