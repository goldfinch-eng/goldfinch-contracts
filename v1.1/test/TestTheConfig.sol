// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../protocol/core/GoldfinchConfig.sol";

contract TestTheConfig {
  address public poolAddress = address(123);
  address public clImplAddress = address(124);
  address public clFactoryAddress = address(125);
  address public tokenAddress = address(126);
  address public creditDeskAddress = address(127);
  address public treasuryReserveAddress = address(128);
  address public trustedForwarderAddress = address(129);
  address public cUSDCAddress = address(130);
  address public goldfinchConfigAddress = address(131);

  function testTheEnums(address configAddress) public {
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TransactionLimit), 1);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.TotalFundsLimit), 2);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.MaxUnderwriterLimit), 3);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.ReserveDenominator), 4);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator), 5);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays), 6);
    GoldfinchConfig(configAddress).setNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays), 7);

    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Token), tokenAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.Pool), poolAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CreditDesk), creditDeskAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CreditLineFactory), clFactoryAddress);
    GoldfinchConfig(configAddress).setAddress(
      uint256(ConfigOptions.Addresses.TrustedForwarder),
      trustedForwarderAddress
    );
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.CUSDCContract), cUSDCAddress);
    GoldfinchConfig(configAddress).setAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig), goldfinchConfigAddress);

    GoldfinchConfig(configAddress).setTreasuryReserve(treasuryReserveAddress);
  }
}
