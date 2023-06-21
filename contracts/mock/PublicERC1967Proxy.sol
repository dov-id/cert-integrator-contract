// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PublicERC1967Proxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}

    function implementation() external view returns (address) {
        return _implementation();
    }
}
