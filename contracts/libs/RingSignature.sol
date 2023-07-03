// SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.5.3 <0.9.0;
pragma solidity ^0.8.0;

import "elliptic-curve-solidity/contracts/EllipticCurve.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
    Procedure verify_signature(M, A[1], A[2], ..., A[n], I, c[1], r[1],
        c[2], r[2], ..., c[n], r[n]):
        For i <- 1..n
            X[i] <- c[i]*A[i]+r[i]*G
            Y[i] <- c[i]*I+r[i]*H(A[i])
        End For
        If H(H(M) || X[1] || Y[1] || X[2] || Y[2] || ... || X[n] || Y[n]) 
        = Sum[i=1..n](c[i])
            Return "Correct"
        Else
            Return "Incorrect"
        End If
    End Procedure 
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
        bytes[] memory publicKeys_
    ) internal pure returns (bool) {
        return _verify(message_, i_, c_, r_, publicKeys_);
    }

    function _verify(
        bytes memory message_,
        uint256 i_,
        uint256[] memory c_,
        uint256[] memory r_,
        bytes[] memory publicKeys_
    ) private pure returns (bool) {
        uint256 length_ = publicKeys_.length;

        //  converting public keys from such format `04f521fc7ea86b81a8b8eb4a635c7970ad4d9775a18d793c35c472ace32580e63e62643ed2cc87f9ab1ea934099d5c99bbf4719aab21d22cf5d528ce94b36bf4ee`
        //  to elliptic curve coordinates
        Coordinate[] memory publicKeysCoordinates_ = new Coordinate[](length_);

        for (uint256 k = 0; k < length_; k++) {
            (uint256 x_, uint256 y_) = _convertPublicKeyToCoordinates(publicKeys_[k]);
            publicKeysCoordinates_[k].x = x_;
            publicKeysCoordinates_[k].y = y_;
        }

        Coordinate[] memory X_ = new Coordinate[](length_);
        uint256[] memory Y_ = new uint256[](length_);

        //For i <- 1..n
        for (uint256 k = 0; k < length_; k++) {
            // X[i] <- c[i]*A[i]+r[i]*G
            Coordinate memory a;
            Coordinate memory b;
            (a.x, a.y) = EllipticCurve.ecMul(
                c_[k],
                publicKeysCoordinates_[k].x,
                publicKeysCoordinates_[k].y,
                AA,
                PP
            );
            (b.x, b.y) = EllipticCurve.ecMul(r_[k], GX, GY, AA, PP);

            (X_[k].x, X_[k].y) = EllipticCurve.ecAdd(a.x, a.y, b.x, b.y, AA, PP);

            //  Y[i] <- c[i]*I+r[i]*H(A[i])
            uint256 hashA_ = uint256(
                bytes32(abi.encodePacked(publicKeysCoordinates_[k].x, publicKeysCoordinates_[k].y))
            ); // there is should be hashing, not just encoding, talk about changing it
            Y_[k] = addmod(mulmod(c_[k], i_, NN), mulmod(r_[k], hashA_, NN), NN);
        }
        //End For

        // H(H(M) || X[1] || Y[1] || X[2] || Y[2] || ... || X[n] || Y[n])
        bytes32 messageHash_ = sha256(message_);
        bytes memory concated_ = bytes(Strings.toString(uint256(messageHash_)));

        for (uint256 k = 0; k < length_; k++) {
            concated_ = abi.encodePacked(
                concated_,
                _toUpperCase(_removeHexPrefix(Strings.toHexString(X_[k].x))),
                " ",
                _toUpperCase(_removeHexPrefix(Strings.toHexString(X_[k].y))),
                Strings.toString(Y_[k])
            );
        }
        bytes32 concatenatedHash_ = sha256(bytes(concated_));

        // Sum[i=1..n](c[i])
        uint256 sum_ = 0;
        for (uint256 k = 0; k < length_; k++) {
            sum_ = addmod(sum_, c_[k], NN);
        }

        return sum_ == uint256(concatenatedHash_);
    }

    // An Ethereum public key is a point on an elliptic curve, meaning it is a set
    // of x and y coordinates that satisfy the elliptic curve equation.
    // In simpler terms, an Ethereum public key is two numbers, joined together.
    function _convertPublicKeyToCoordinates(
        bytes memory publicKey_
    ) private pure returns (uint256 x_, uint256 y_) {
        if (publicKey_.length == 0 || uint8(publicKey_[0]) != 4) {
            revert("RingSignature: wrong public key formt");
        }

        uint256 byteLen_ = 32;

        bytes memory tmpX = new bytes(byteLen_);
        for (uint256 i = 0; i < byteLen_; i++) {
            tmpX[i] = publicKey_[i + 1];
        }

        bytes memory tmpY = new bytes(byteLen_);
        for (uint256 i = 0; i < byteLen_; i++) {
            tmpY[i] = publicKey_[i + 1 + byteLen_];
        }

        x_ = uint256(bytes32(tmpX));
        y_ = uint256(bytes32(tmpY));
    }

    //I suppose that we can concat bytes, so all string helper functions would be eliminated later

    function _removeHexPrefix(string memory hexString_) private pure returns (string memory) {
        if (bytes(hexString_)[0] == "0" && bytes(hexString_)[1] == "x") {
            hexString_ = _substring(hexString_, 2);
        }

        // kostyl, because in GO trims trail zero :'(
        // must be changed
        if (bytes(hexString_)[0] == "0") {
            hexString_ = _substring(hexString_, 1);
        }

        return hexString_;
    }

    function _substring(
        string memory str_,
        uint256 startIndex_
    ) private pure returns (string memory) {
        bytes memory strBytes_ = bytes(str_);
        uint256 oldLength_ = strBytes_.length;

        require(startIndex_ < oldLength_, "RingSignature: Invalid start index");

        uint256 newLength_ = oldLength_ - startIndex_;
        bytes memory result_ = new bytes(newLength_);

        for (uint256 i = 0; i < newLength_; i++) {
            result_[i] = strBytes_[i + startIndex_];
        }

        return string(result_);
    }

    function _toUpperCase(string memory str_) private pure returns (string memory) {
        bytes memory strBytes_ = bytes(str_);
        uint256 length_ = strBytes_.length;

        for (uint256 i = 0; i < length_; i++) {
            if ((strBytes_[i] >= 0x61) && (strBytes_[i] <= 0x7A)) {
                strBytes_[i] = bytes1(uint8(strBytes_[i]) - 32);
            }
        }

        return string(strBytes_);
    }
}

// 72089766972633511249573876350515456637017850083706688218916405066191437348254D0A9A31CB9910CBD2574BEC31DA8D488C4D7619B282E634CA9AC5B74A8536910 8B05FBD79AD934C92B5AF3C6AC5DB5906D6062CBF16466F2AA4C41D872E1A6D113072130549819321626987201459466390559395968119875954521590235826953421028081D07EF8257680FDAD07FBB3ECB221A4C047F9ABABEEEB5FA7194FE97183F88266 6CBC4D0EEAE7107D61352933C0DB5E13FE22C0AE85C4F59B211A0ADF730ED11F4559210410950300935298958318862394612372995440482464970689198176880493888786397D0746B668E60846E46931E4980D2F236ACE3C4DBA841268CC705DE11CB60CF DCF06AC446D554ABCEF6E96FC3C857531F950BBB41B7F22B32AD2215E5CF2B3876372992482210355057669603929776828318234235032804943144639663158332687776477E82BE2EADF980363942C2D8A0A83AF55C0E5CD72658F01E6FDF9A8EBA66F464 FDDEE4418AC724BB6CA9E6DA10382E409B73AE5693CF2283C07A398E3F68B08144298103890422863828904986901117702420720874141743683520887543425440160701158C0DF0C0DBF763FCDEE581079F7AA280BD91276D0166D0DB94E0B025183A05654 2122383E473D1D31B343444EEE67CC3C317BBDDEEFEEF3847D4EB7EBDA756A4372145076088697473484812138855750341467347846840207311738072276565465330410072
// 71056264974722397856211609556882889849244578790967303908586156115513854471227D0A9A31CB9910CBD2574BEC31DA8D488C4D7619B282E634CA9AC5B74A8536910 8B05FBD79AD934C92B5AF3C6AC5DB5906D6062CBF16466F2AA4C41D872E1A6D113072130549819321626987201459466390559395968119875954521590235826953421028081D07EF8257680FDAD07FBB3ECB221A4C047F9ABABEEEB5FA7194FE97183F88266 6CBC4D0EEAE7107D61352933C0DB5E13FE22C0AE85C4F59B211A0ADF730ED11F4559210410950300935298958318862394612372995440482464970689198176880493888786397D0746B668E60846E46931E4980D2F236ACE3C4DBA841268CC705DE11CB60CF DCF06AC446D554ABCEF6E96FC3C857531F950BBB41B7F22B32AD2215E5CF2B3876372992482210355057669603929776828318234235032804943144639663158332687776477E82BE2EADF980363942C2D8A0A83AF55C0E5CD72658F01E6FDF9A8EBA66F464 FDDEE4418AC724BB6CA9E6DA10382E409B73AE5693CF2283C07A398E3F68B08144298103890422863828904986901117702420720874141743683520887543425440160701158C0DF0C0DBF763FCDEE581079F7AA280BD91276D0166D0DB94E0B025183A05654 2122383E473D1D31B343444EEE67CC3C317BBDDEEFEEF3847D4EB7EBDA756A4372145076088697473484812138855750341467347846840207311738072276565465330410072
