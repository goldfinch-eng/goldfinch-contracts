// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../protocol/core/Pool.sol";

contract TestPool is Pool {
  function _getNumShares(uint256 amount) public view returns (uint256) {
    return getNumShares(amount);
  }

  function _usdcMantissa() public pure returns (uint256) {
    return usdcMantissa();
  }

  function _tokenMantissa() public pure returns (uint256) {
    return tokenMantissa();
  }

  function _usdcToToken(uint256 amount) public pure returns (uint256) {
    return usdcToToken(amount);
  }

  function _setSharePrice(uint256 newSharePrice) public returns (uint256) {
    sharePrice = newSharePrice;
  }
}
