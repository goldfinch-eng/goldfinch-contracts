https://gist.github.com/TCHKVSKY/fc8b18b79aa15a99b61f92e0d1e93e1b

### critical = 0 high = 0 medium = 2 low = 2 gas_optimization = 1 informational = 11 total = 16

---

## Medium Risk

### `SafeERC20Transfer` - Not compatible with nonconforming ERC20 implementations

**Severity:** _Medium Risk_

**Context:** [SafeERC20Transfer.sol#L22](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/library/SafeERC20Transfer.sol#L22), [SafeERC20Transfer.sol#L42](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/library/SafeERC20Transfer.sol#L42), [SafeERC20Transfer.sol#L61](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/library/SafeERC20Transfer.sol#L61)

**Description:**

The custom `SafeERC20Transfer` used performs a check to enforce a `true` return value from a non-reverting call. This mitigates problems with contracts like the old [MiniMe implementation](https://github.com/Giveth/minime/commit/ea04d950eea153a04c51fa510b068b9dded390cb), where failed transfers do not revert and simply return `false`.

There are, however, other nonconforming ERC20 implementations that will revert at all times if called through the `SafeERC20Transfer` reviewed. Any ERC20 token not returning a boolean will fail (https://medium.com/@chris_77367/explaining-unexpected-reverts-starting-with-solidity-0-4-22-3ada6e82308c).

The current USDT token is one example of a token which does not return a boolean on transfers.

Custom SafeERC20Transfer lib:

```
bool success = erc20.transfer(to, amount);
require(success, message);
```

Comparing to the latest OZ lib ([safeTransfer](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8b778fa20d6d76340c5fac1ed66c80273f05b95a/contracts/token/ERC20/utils/SafeERC20.sol#L22-L28) and [\_callOptionalReturn](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8b778fa20d6d76340c5fac1ed66c80273f05b95a/contracts/token/ERC20/utils/SafeERC20.sol#L99-L115)), where the USDT no return value is handled.

**Recommendation:**

Make use of the OpenZeppelin `SafeERC20` library over the custom `SafeERC20Transfer` library. There is a version in the existing OpenZeppelin dependencies.

**Goldfinch:**

**Spearbit:**

### `UcuProxy.upgradeImplementation` - Possible front running issues

**Severity:** _Medium Risk_

**Context:** [File.sol#L123](github-permalink)

**Description:**
In order to upgrade the implementation of a `UcuProxy`, a new implementation needs to be added to `ImplementationRepository` by calling `ImplementationRepository.append` first, then (optionally), the upgrade data should be determined by calling `ImplementationRepository.setUpgradeDataFor`, and finally, `UcuProxy.upgradeImplementation` should be called to launch the actual upgrade.

In case the calls to `ImplementationRepository.setUpgradeDataFor`, `UcuProxy.upgradeImplementation` are executed in a non-atomic way (i.e. not within a single transaction), the upgrade process is susceptible to miner/validator front running attack vector, where the miner can abandon the `ImplementationRepository.setUpgradeDataFor` transaction, or process it after the call to `UcuProxy.upgradeImplementation`, therefore causing an upgrade without initialization.

In addition, the owner of `ImplementationRepository` can front run a call to `UcuProxy.upgradeImplementation` changing `nextImplementation` and/or the proposed upgrade data.

**Recommendation:**
As for the first issue, consider removing `ImplementationRepository.setUpgradeDataFor` and including its logic in `ImplementationRepository.append` instead.

As for the second issue, consider adding the expected values for the implementation and the upgrade data to `UcuProxy.upgradeImplementation`, or alternatively, introduce a timelock mechanism to limit the potential timing of changes to the current implementation.

**Goldfinch:**

**Spearbit:**

<br>

## Low Risk

### `ImplementationRepository._remove` - violates assumptions about upgradeability

**Severity:** _Low Risk_

**Context:**

- Assumption 1: `upgradeDataFor` assumes `TranchedPool` is upgrading from a particular version [ImplementationRepository.sol#L197](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/ImplementationRepository.sol#L197)
- Assumption 2: `TranchedPool`s can be upgraded if there is a new implementation in the same lineage [ImplementationRepository.sol#L199](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/ImplementationRepository.sol#L199)

**Description:**

Assumption 1 is violated when `remove`ing. In most cases there is no impact, unless `upgradeDataFor` depends on the previous implementation being a particular version.

Assumption 2 is violated when `remove`ing due to the statement: ` _nextImplementationOf[toRemove] = INVALID_IMPL;`. When the proxy attempts to upgrade _from_ a removed implementation, `ImplementationRepository.nextImplementationOf` returns `address(0)` restricting an upgrade from proceeding.

Marked as low risk as the `ImplementationRepository` itself is upgradeable.

**Recommendation:**

For assumption 1, consider:

- creating a checklist to review before appending or removing an implementation to confirm these problems are not present
- ensuring all implementations in a lineage are compatible with each other and there is no version dependency on a particular previous version when using `upgradeDataFor`

For assumption 2, consider:

- leaving `_nextImplementationOf[toRemove]` untouched for the removed implementation, provided there is no conflict in upgrading each version to any other future version. NOTE: this runs the risk of the version being upgraded to later being removed which is acceptable as `_nextImplementationOf[toRemove]` is not deleted.

**Goldfinch:**

**Spearbit:**

### Solidity version no longer pinned to `pragma solidity 0.6.12`

**Severity:** _Low Risk_

**Context:** [IERC173.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/interfaces/IERC173.sol#L3), [IVersioned.sol#L4](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/interfaces/IVersioned.sol#L4), [SafeMath.sol#L1](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/library/SafeMath.sol#L1)[GoldfinchFactory.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/GoldfinchFactory.sol#L3), [TranchedPoolImplementationRepository.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPoolImplementationRepository.sol#L3), [ImplementationRepository.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/ImplementationRepository.sol#L3), [VersionedImplementationRepository.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L3), [UcuProxy.sol#L3](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/UcuProxy.sol#L3)

**Description:**

Solidity version no longer pinned to `pragma solidity 0.6.12` and instead uses `pragma solidity >=0.6.12`

**Recommendation:**

For production releases use a pinned solidity version.

**Goldfinch:**

**Spearbit:**

<br>

## Gas Optimization

### `ImplementationRepository._append` - Multiple reads to `_currentOfLineage[lineageId]`

**Severity:** _Informational_ / _Gas Optimization_

**Context:** [ImplementationRepository.sol#L171-L183](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/ImplementationRepository.sol#L171-L183)

**Description:**

Multiple reads to `_currentOfLineage[lineageId]`.

**Recommendation:**

Can save a tiny bit of gas by using the cached read:

```diff
/// @notice Set an implementation to the current implementation
/// @param implementation implementation to set as current implementation
/// @param lineageId id of lineage to append to
function _append(address implementation, uint256 lineageId) internal virtual {
  require(Address.isContract(implementation), "not a contract");
  require(!_has(implementation), "exists");
  require(_lineageExists(lineageId), "invalid lineageId");
+
+  address oldImplementation = _currentOfLineage[lineageId];
-  require(_currentOfLineage[lineageId] != INVALID_IMPL, "empty lineage");
+  require(oldImplementation != INVALID_IMPL, "empty lineage");

-  address oldImplementation = _currentOfLineage[lineageId];
  _currentOfLineage[lineageId] = implementation;
  lineageIdOf[implementation] = lineageId;
  _nextImplementationOf[oldImplementation] = implementation;

  emit Added(lineageId, implementation, oldImplementation);
}
```

**Goldfinch:**

**Spearbit:**

<br>

## Informational

### `StakingRewards` - unused functions

**Severity:** _Informational_

**Context:** [StakingRewards.sol#L140](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/rewards/StakingRewards.sol#L140), [StakingRewards.sol#L931](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/rewards/StakingRewards.sol#L931), [StakingRewards.sol#L59](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/rewards/StakingRewards.sol#L59)

**Description:**

`ZAPPER_ROLE` no longer has special permission meaning the zapper functions are unneeded.

**Recommendation:**

Remove the two unused functions and one unused constant.

**Goldfinch:**

**Spearbit:**

### `VersionedImplementationRepository` - Pack version tightly

**Severity:** _Informational_ / _Gas Optimization_

**Context:** [VersionedImplementationRepository.sol#L21](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L21), [VersionedImplementationRepository.sol#L54](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L54), [VersionedImplementationRepository.sol#L60](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L60), [VersionedImplementationRepository.sol#L65](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L65)

**Description:**

Packing the `uint8` array packs into `bytes` 3 words wide (i.e. `abi.encodePacked([1,0,9])` packs into `0x000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009 `).

Packing tighter saves some gas: `abi.encode(version[0], version[1], version[2])` packs into `0x010009`.

**Recommendation:**

Modify each instance of `abi.encodePacked(version)` (and `abi.encode(version)` ) to `abi.encode(version[0], version[1], version[2])`.

```diff
function getByVersion(uint8[3] calldata version) external view returns (address) {
+  return _byVersion[abi.encodePacked(version[0], version[1], version[2])];
-  return _byVersion[abi.encodePacked(version)];
}

...snip...

function _insertVersion(uint8[3] memory version, address impl) internal {
  require(!_hasVersion(version), "exists");
+  _byVersion[abi.encodePacked(version[0], version[1], version[2])] = impl;
-  _byVersion[abi.encodePacked(version)] = impl;
  emit VersionAdded(version, impl);
}

function _removeVersion(uint8[3] memory version) internal {
+  bytes memory versionKey = abi.encode(version[0], version[1], version[2]);
+  address toRemove = _byVersion[versionKey];
-  address toRemove = _byVersion[abi.encode(version)];
+  _byVersion[versionKey] = INVALID_IMPL;
-  _byVersion[abi.encodePacked(version)] = INVALID_IMPL;
  emit VersionRemoved(version, toRemove);
}

function _hasVersion(uint8[3] memory version) internal view returns (bool) {
+  return _byVersion[abi.encodePacked(version[0], version[1], version[2])] != INVALID_IMPL;
-  return _byVersion[abi.encodePacked(version)] != INVALID_IMPL;
}
```

Modify comment [VersionedImplementationRepository.sol#L12](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/VersionedImplementationRepository.sol#L12). `address` takes up a single slot, `bytes` are simply hashed to determine which storage slot to use.

**Goldfinch:**

**Spearbit:**

### `UcuProxy` - Imports different `Address` implementation

**Severity:** _Informational_

**Context:** [UcuProxy.sol#L8](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/UcuProxy.sol#L8)

**Description:**

`UcuProxy` imports a different Address than the one imported through `StakingRewards`

@openzeppelin/contracts/utils/Address.sol
vs
@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

**Recommendation:**

Consolidate on one of the two version, `@openzeppelin/contracts/utils/Address.sol` is the more up to date of the two.

**Goldfinch:**

**Spearbit:**

### Spellcheck on comments

**Severity:** _Informational_

**Context:** [ImplementationRepository.sol#L10](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/proxy/ImplementationRepository.sol#L10), [TranchedPool.sol#L109](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L109) and others

**Description:**

Some misspelled words in natspec comments.

**Recommendation:**

Good practice to make use of a spellchecker IDE plugin.

**Goldfinch:**

**Spearbit:**

### `TranchedPool` - Centralization risk with the two transfers to admin controlled address

**Severity:** _Informational_

**Context:** [TranchedPool.sol#L332](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L332)

**Description:**

Calling `emergencyShutdown` transfers funds to the `reserveAddress`. The current implementation restricts admin from resetting the `reserveAddress`, however, the logic in the [GoldfinchConfig contract](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/GoldfinchConfig.sol#L20) is upgradeable.

It is noted that GoldfinchConfig upgrades are currently controlled by a multisig.

**Recommendation:**

Consider:

- documenting risk
- adding timelock to GoldfinchConfig upgrades

**Goldfinch:**

**Spearbit:**

### Mixed use of SafeMath for `numSlices +/- 1`

**Severity:** _Informational_ / _Gas Optimization_

**Context:** [TranchedPool.sol#L572](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L572), [TranchedPool.sol#L285](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L285), [TranchedPool.sol#L308](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L308), [TranchedPool.sol#L593](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L593)

**Description:**

SafeMath is used in some places and not others for the same calculation.

**Recommendation:**

Adopt a style guide to use SafeMath in a consistent way.

In instances where over/under flow is not possible, use unchecked arithmetic (default in the Solidity version used; 0.6.12) add a comment on why it is not possible to over/under flow.

**Goldfinch:**

**Spearbit:**

### `TranchedPool` - `safeERC20TransferFrom` used where `safeERC20Transfer` is sufficient

**Severity:** _Informational_ / _Gas Optimization_

**Context:** [TranchedPool.sol#L256](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L256), [TranchedPool.sol#L487](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L487), [TranchedPool.sol#L557](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L557). May exist in unreviewed contracts as well.

**Description:**

The `TranchedPool` already has sufficient access to call `transfer` for tokens it owns; using `transferFrom` incurs additional gas costs as the `allowed` `mapping` [is updated](https://etherscan.io/address/0xa2327a938febf5fec13bacfb16ae10ecbc4cbdcf#code#L846)

**Recommendation:**

When transferring from `address(this)` use a `safeTransfer` over `safeTransferFrom`

**Goldfinch:**

**Spearbit:**

### `TranchedPool` - `public` functions can be `external`

**Severity:** _Informational_

**Context:** [TranchedPool.sol#L174](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L174), [TranchedPool.sol#L137](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L137), [TranchedPool.sol#L332](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L332), [TranchedPool.sol#L355](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L355), [TranchedPool.sol#L363](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L363), [TranchedPool.sol#L377](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L377), [TranchedPool.sol#L427](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L427), [TranchedPool.sol#L453](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L453)

**Description:**

`public` functions not called by the contract can be `external`.

**Recommendation:**

Edit the function visibility to `external`.

**Goldfinch:**

**Spearbit:**

### Inconsistent use of `_msgSender()` and `msg.sender`

**Severity:** _Informational_

**Context:** [TranchedPool.sol#L123](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L123)

**Description:**

Throughout `msg.sender` is used over `_msgSender`.

**Recommendation:**

Select a consistent convention. If not using GSN or related relay, consider simply `msg.sender` throughout.

**Goldfinch:**

**Spearbit:**

### `TranchedPool` - duplicate/unused SafeMath import

**Severity:** _Informational_

**Context:** [TranchedPool.sol#L8](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L8)

**Description:**

`SafeMath` import line in `TranchedPool`. `SafeMath` is already imported and used though `BaseUpgradeablePausable`.

**Recommendation:**

Remove unused import.

**Goldfinch:**

**Spearbit:**

### `TranchedPool` changes are backwards incompatible

**Severity:** _Informational_

**Context:** [TranchedPool.sol#L41](https://github.com/warbler-labs/mono/blob/00845f86c54ce13ed6c14c1a11441f247ca75504/packages/protocol/contracts/protocol/core/TranchedPool.sol#L41)

**Description:**
[PR#779](https://github.com/warbler-labs/mono/pull/779) contains breaking changes for `TranchedPool`, for instance, changing `poolSlices` to be a mapping instead of an array would cause the previous values stored in the array to be effectively lost.

**Recommendation:**
Make sure that this version of code is not used to upgrade already deployed `TranchedPool` contracts, and rather used for new deployments only instead.

**Goldfinch:**

**Spearbit:**
