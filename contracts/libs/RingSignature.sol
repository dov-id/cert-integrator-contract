// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../elliptic-curve-solidity/contracts/EllipticCurve.sol";

/**
 *  1. This library is needed for operating with ring signature in Secp256k1 elliptic curve.
 *  Signature specification can be found in [web archive](https://web.archive.org/web/20160514065822/https://cryptonote.org/cns/cns002.txt).
 *
 *  2. Pseudo code for verifying such signature looks like:
 *   Procedure verify_signature(M, A[1], A[2], ..., A[n], I, c[1], r[1],
 *       c[2], r[2], ..., c[n], r[n]):
 *       For i <- 1..n
 *           X[i] <- c[i]*A[i]+r[i]*G
 *           Y[i] <- c[i]*I+r[i]*H(A[i])
 *       End For
 *       If H(H(M) || X[1] || Y[1] || X[2] || Y[2] || ... || X[n] || Y[n])
 *       = Sum[i=1..n](c[i])
 *           Return "Correct"
 *       Else
 *           Return "Incorrect"
 *       End If
 *   End Procedure
 *
 *  3. Gas usage for `verify` method is:
 *      a. Min: 7040807
 *      b. Avg: 12077960
 *      c. Max: 23877055
 */
library RingSignature {
    struct Coordinate {
        uint256 x;
        uint256 y;
    }

    //init values for Secp256k1 elliptic curve
    uint256 public constant NN =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    uint256 public constant GX =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 public constant BitSize = 256;

    function verify(
        bytes memory message_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_
    ) internal pure returns (bool) {
        return _verify(message_, i_, c_, r_, publicKeysX_, publicKeysY_);
    }

    function _verify(
        bytes memory message_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        uint256[] memory publicKeysX_,
        uint256[] memory publicKeysY_
    ) private pure returns (bool) {
        uint256 length_ = publicKeysX_.length;

        Coordinate[] memory X_ = new Coordinate[](length_);
        uint256[] memory Y_ = new uint256[](length_);

        //For i <- 1..n
        for (uint256 k = 0; k < length_; k++) {
            // X[i] <- c[i]*A[i]+r[i]*G
            Coordinate memory a;
            Coordinate memory b;
            (a.x, a.y) = EllipticCurve.ecMul(c_[k], publicKeysX_[k], publicKeysY_[k], AA, PP);
            (b.x, b.y) = EllipticCurve.ecMul(r_[k], GX, GY, AA, PP);

            (X_[k].x, X_[k].y) = EllipticCurve.ecAdd(a.x, a.y, b.x, b.y, AA, PP);

            //  Y[i] <- c[i]*I+r[i]*H(A[i])
            uint256 hashA_ = uint256(sha256(abi.encodePacked(publicKeysX_[k], publicKeysY_[k])));
            Y_[k] = addmod(mulmod(c_[k], i_, NN), mulmod(r_[k], hashA_, NN), NN);
        }
        //End For

        // H(H(M) || X[1] || Y[1] || X[2] || Y[2] || ... || X[n] || Y[n])
        bytes memory concatenated_ = abi.encodePacked(uint256(sha256(message_)));
        for (uint256 k = 0; k < length_; k++) {
            concatenated_ = abi.encodePacked(concatenated_, X_[k].x, X_[k].y, Y_[k]);
        }

        bytes32 concatenatedHash_ = sha256(concatenated_);

        // Sum[i=1..n](c[i])
        uint256 sum_ = 0;
        for (uint256 k = 0; k < length_; k++) {
            sum_ = addmod(sum_, c_[k], NN);
        }

        return sum_ == uint256(concatenatedHash_);
    }
}
