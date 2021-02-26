// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../protocol/GoldfinchConfig.sol";

contract TestTheConfig {
  address public poolAddress = address(0);
  address public clImplAddress = address(1);
  address public clFactoryAddress = address(2);
  address public tokenAddress = address(3);
  address public creditDeskAddress = address(4);
  address public treasuryReserveAddress = address(5);

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

    GoldfinchConfig(configAddress).setCreditLineImplementation(clImplAddress);
    GoldfinchConfig(configAddress).setTreasuryReserve(treasuryReserveAddress);
  }
}
