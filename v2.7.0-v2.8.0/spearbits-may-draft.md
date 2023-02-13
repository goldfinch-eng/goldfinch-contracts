https://gist.github.com/misirov/ab684ccbea5cff96d560a4783a242aa9

critical = 0
high = 0
medium = 2
low = 3
gas_optimization = 4
informational = 8
total = 17

<hr>

## Medium Risk

### Position seller might trick a buyer to buy a depreciated token

**Severity:** _Medium_

**Description:** Positions are implemented as ERC721, and therefore can be traded on decentralized exchanges. A position seller can spot the actual swap transaction in the mem-pool and front-run it with a transaction that depreciates the position value (e.g. calling `unstake`, `getReward`, etc), causing the buyer to buy a depreciated token. In the worst case, liquidity can be totally emptied from the position, since unstaking the entire amount does not cause the burn of the token.

**Recommendation:** The issue is caused due to the fact that the `tokenId` is not bonded to changes in the position storage state. We propose to implement a mechanism where there are two different identifiers for any token, an internal identifier that should stay constant throughout the entire token life-cycle (it can be implemented as a counter), and an external identifier. Whenever the position storage data is changed, the old token should be burned, and a new token should be minted using a new external identifier. The external identifier might be implemented as `hash(internal_id, version)`, where the version is incremented whenever the position storage data is changed.

**Goldfinch:**

**Spearbit:**

### Locked OpenZeppelin dependency 3.0.0 contains memory leaks that causes increased costs and could prevent execution

**Severity:** _Medium Risk_ / _Gas Optimization_

**Context:** [ERC721.sol#L137](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/external/ERC721.sol#L137) ~ 20 references to this throughout the codebase
All instances of SafeMath `sub div mod` are affected
`sub` ~140 references
`div` ~100 references
`mod` ~15 references

**Description:** The Goldfinch contracts have a locked dependency of @openzeppelin/contracts-upgradeable@3.0.0. Versions prior to 3.4 contain memory leaks across various parts, such as its Enumerable types and SafeMath operators. What this means is that each subsequent call of one of these affected methods results in a quadratically increasing gas cost of it.
In the best case, this results in end-users unnecessarily paying an increased gas overhead for transacting with the contracts. In the worst case, this could bubble up the gas usage to the point where the contracts can't execute.

**Recommendation:** It is recommended to upgrade the dependency to the latest available minor version, and generally an attempt should be made at each future deployment to check if there is a newer compatible minor version and inspect its associated changelog for any fixes that may affect the current set of contracts. It is duly noted that upgrading to the next major version, 4.0, is not possible safely with the current Goldfinch deployment, due to it targeting solc 0.6.x and also there existing storage incompatibilities between 3.0 and 4.0 series of OZ upgradables.

The recommended upgrade path is towards the latest @openzeppelin/contracts-upgradeable@3.4.2 following Goldfinch's own due diligence, as it has some vendored parts of those contracts.

The upgrade should resolve all of the SafeMath operator issues, where custom error messages are not utilized. This seems to be the case for the contracts inspected within the scope of this audit. The memory leaking functions are still exposed but noted as deprecated with instructions on how to work around them in the case where custom error messages are utilized.

In the case of the `ownerOf` leak, it will require an override and dropping the deprecated `.get` custom error method with a `.tryGet` and appropriately handling failure conditions as reverts within it.

Albeit the upgrade itself, should at least minimize the risks of bubbling into a situation where the gas limit is reached, as the majority of memory leaking references were SafeMath-based.

**Goldfinch:**

**Spearbit:**

<br>

## Low Risk

### Add postcondition to ensure `interestRedeemed` does not exceed a safe maximum

**Severity:** _Low Risk_

**Context:** [PoolTokens.sol#L146](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L146)

**Description:** The prior modified token properties have postconditions that ensure they are within a safe maximum. Such a postcondition for `interestRedeemed` appears to be missing, which depending on outside logic could cause more than expected or allowable interested to be pulled.

**Recommendation:** Additionally have a check that ensures the interest being redeemed is not above the safely allowable maximum for that specific token.

**Goldfinch:**

**Spearbit:**

### Missing sanity checks on royalty input and output parameters

**Severity:** _Low Risk_

**Context:**
[ConfigurableRoyaltyStandard.sol#L42-L56](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/ConfigurableRoyaltyStandard.sol#L42-L56)
[PoolTokens.sol#L266-L283](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L266-L283)

**Description:** The setter and getter for the royalty is missing a variety of sanity checks to protect end-users. The setters within the scope of the audit appear to be access controlled via an `onlyAdmin` modifier, therefore it is a privileged function and the risk is low. However, a malicious admin could still steal the entire sale price, with the currently missing preconditions. Additionally, the admin could potentially front-run an expensive sale with an MEV sandwich attack where the maximally allowed royalty of a marketplace is charged, before the sale transaction, and then it is reset to a sane value following the sale transaction. In the worst case of a marketplace erroneously handling sales, the current lack of checks could even allow the admin to exceed sale price royalties and dip into a marketplace balance.

**Recommendation:** Add sanity checks ensuring a threshold royalty fee cannot be exceeded to provide some guarantee to end-users on what is deployed. Additionally consider a timelock mechanism before the new fee amount takes effect, to protect users from such hypothetical privileged attacks.

**Goldfinch:**

**Spearbit:**

### Missing null address check on royalty receiver

**Severity:** _Low Risk_

**Context:** [ConfigurableRoyaltyStandard.sol#L55](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/ConfigurableRoyaltyStandard.sol#L55)

**Description:** Allows the setting of a royalty, but the royalty receiver is not validated and could end up being a null address, which could result in accidental scenarios where it is omitted while a royalty fee is set, and the royalty does not reach the intended royalty receiver.

**Recommendation:** Have an appropriate precondition via a require statement to ensure the parameter is not being set to null address alongside a non-zero fee.

**Goldfinch:**

**Spearbit:**

<br>

## Gas Optimization

### Two same div ops can be reduced to one to save gas

**Severity:** _Gas Optimization_

**Context:** [StakingRewards.sol#L335](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L335)

**Description:** Following the multiplication, the result is twice divided by `MULTIPLIER_DECIMALS`. This results in an unnecessary extra division operation, as it's being divided by the same constant twice.

**Recommendation:** Cut the operations down to a single SafeMath `div` call, which uses a constant that is the square of `MULTIPLIER_DECIMALS`.

**Goldfinch:**

**Spearbit:**

### Redundant null address check

**Severity:** _Gas Optimization_

**Context:** [PoolTokens.sol#L134-L135](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L134-L135)

**Description:** The condition at L135 would basically ensure that the `token.pool` & `poolAddr` are not a null address, as the `msg.sender`, which this implementation of `_msgSender()` seems to fallback on, should never be able to be the null address.

**Recommendation:** The null address check on L134 is therefore redundant and can be removed, as long as the code on L135 is not modified from its current implementation.

**Goldfinch:**

**Spearbit:**

### Redundant ERC165 interface check already covered by EIP173Proxy

**Severity:** _Gas Optimization_

**Context:**
[PoolTokens.sol#L24](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L24)
[PoolTokens.sol#L289](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L289)
[EIP173Proxy.sol#L34](https://github.com/landakram/hardhat-deploy/blob/master/solc_0.7/proxy/EIP173Proxy.sol#L34)

**Description:** The `PoolTokens` contract is deployed behind a proxy that has its own `supportsInterface` implementation, which does basic checks according to the standard, including ERC165 interface support. Any additional logic handling is then passed to the implementation contract for its own `supportsInterface`. The implementation contract here, unnecessarily checks for ERC165 support once again.

In the case ERC165 support is checked, that condition is unreachable, as it'll be preemptively hit in the EIP173Proxy. In the case ERC2981 support is checked for, or any other unsupported interface, this yields an additional unnecessary condition check that will never be true.

**Recommendation:** Remove the unnecessary ERC165 interface definition in the `PoolTokens` contract and the check for it in the `supportsInterface` function within.

**Goldfinch:**

**Spearbit:**

### Redundant non-existent token checks in dependency

**Severity:** _Gas Optimization_

**Context:**
[ERC721.sol#L397-L399](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/external/ERC721.sol#L397-L399)
[ERC721.sol#L269-L270](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/external/ERC721.sol#L269-L270)

**Description:** In the case the spender is not the owner, a redundant non-existent token check occurs that is not necessary via the `getApprove` call.

**Recommendation:** Since this is in an open-source dependency of the project, it be best to notify the maintaining team but also consider contributing a fix, whereby there is a `getApproved` internal variant available for this callchain, that does not redundantly recheck token existence, or even just replaces the `getApproved` call with `_tokenApprovals[tokenId]` as that is all the function would contain anyways without the require.

**Goldfinch:**

**Spearbit:**

<br>

## Informational

### Redundant calls to `updateReward(0)`

**Severity:** _Informational_
**Context:**
[StakingRewards.sol#L383](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L383)
[StakingRewards.sol#L392](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L392)
[StakingRewards.sol#L446](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L446)

**Description:**
The functions mentioned call `updateReward(0)`, while in practice it is redundant since the same lines of code are executed twice.

**Recommendation:**
Consider removing the call to `updateReward(0)`.

**Goldfinch:**

**Spearbit:**

### Call to `_additionalRewardsPerTokenSinceLastUpdate` during `updateReward` always yields 0

**Severity:** _Informational_ / _Gas Optimization_

**Context:**
[StakingRewards.sol#L933-L944](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L933-L944)
[StakingRewards.sol#L233-L242](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L233-L242)
[StakingRewards.sol#L227-L231](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L227-L231)
[StakingRewards.sol#L200-L225](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L200-L225)

**Description:** During the callchain to `updateReward(tokenId)`, with a non-zero parameter, `_additionalRewardsPerTokenSinceLastUpdate(block.timestamp)` is called via L944 -> L240 -> L230 to L212. It depends on the `lastUpdateTime`, which has already been set to the current `block.timestamp` in the lines prior to L944. Meaning there might be some issues in the logic or that the call to at L230 is dead code.

**Recommendation:** Ensure the logic is currently correct above all and that `lastUpdateTime` should indeed be set before L944.

In the case that it is, supplementing L230 with a preemptive return when `block.timestamp`and `lastUpdateTime` are equal.

**Goldfinch:**

**Spearbit:**

### Replace `updateReward` modifier with inlined calls for consistency

**Severity:** _Informational_ / _Gas Optimization_

**Context:** [File.sol#L123](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L928-L931)

**Description:** This modifier pattern is introduced but is not consistently usable across the codebase. In certain cases, the function is directly called, as it is not possible to call it only before or after all logic, but somewhere in between. This has introduced an ambiguity in its use and introduced cases also where there are multiple redundant calls to the same function, leading to a waste of gas, inefficient EVM usage, and extra gas cost to end-users.

**Recommendation:** Remove the `updateReward` modifier, and inline the calls where necessary.

**Goldfinch:**

**Spearbit:**

### Fully annotate all public interfaces using NatSpec

**Severity:** _Informational_

**Context:** [PoolTokens.sol#L208-L214](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L208-L214)

**Description:** There are multiple instances of public interfaces (anything that makes it into the ABI) that are missing supporting NatSpec annotations. This hurts code readability, understanding and maintenance.

**Recommendation:** Appropriately annotate all the public interfaces using NatSpec.

**Goldfinch:**

**Spearbit:**

### Document all known and expected behaviours

**Severity:** _Informational_

**Context:** [PoolTokens.sol#L224-L231](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L224-L231)

**Description:** In addition to returning, the function in question reverts when the `tokenId` does not exist. This is not noted and leads to auditors or anyone else inspecting the code having to dig deeper into each function to understand what all the possible behaviours and effects are. In turn, this can introduce development overhead in the best case, where the documentation does not fully cover associated effects or in the worst case an assumption that it doesn't revert and build a future feature that fails as it lacked that assumption.

**Recommendation:** Attempt to document all known and expected effects using `@dev` natspec tag, where it can be concisely communicated within the documentation or at least state there are additional exceptions.

**Goldfinch:**

**Spearbit:**

### Set internally unused public visibility to external for keeping consistent with external/internal pattern

**Severity:** _Informational_

**Context:**
[PoolTokens.sol#L233](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L233)
[StakingRewards.sol#L614-L627](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/rewards/StakingRewards.sol#L614-L627)

**Description:** The contracts in scope authored by Goldfinch generally follow the external/internal implementation pattern, whereby an external function calls into an internal variant prefixed with an underscore that implements the actual logic.

The functions in context, such as `validPool`, unnecessarily breaks from this pattern with the public visibility specifier, which is unnecessary, as it does not appear to be accessed internally, and could lead to unexpected issue, if the public and internal variant were to deviate in some future iteration and the internal variant used internally in certain parts, and the public elsewhere.

**Recommendation:** Stay consistent with the external/internal pattern and make the function external only.

**Goldfinch:**

**Spearbit:**

### Naming clash between declared variable and struct property "pool"

**Severity:** _Informational_

**Context:** [PoolTokens.sol#L238-L243](https://github.com/warbler-labs/mono/blob/c15f502b9ce617d4b6daee5765446cf3003bba54/packages/protocol/contracts/protocol/core/PoolTokens.sol#L238-L243)

**Description:** A variable named `pool` is declared at the beginning of the function scope. Within this function scope, the `TokenInfo` `pool` property is accessed as well. This naming clash can cause confusion and ambiguity. In the case of Visual Studio Code with Solidity and auditor functions, it erroneously states that the `pool` property on L243 is the variable declared on L238.

**Recommendation:** Name the declared variable something different that still keeps its intent clear.

**Goldfinch:**

**Spearbit:**

### Check and upgrade to latest compatible dependencies when possible instead of vendoring them

**Severity:** _Informational_

**Context:** [PR#474](https://github.com/warbler-labs/mono/pull/474)

**Description:** The greatest portion of code additions from this PR is the vendoring of a number of dependency contracts for one function that was missing the virtual keyword to be overridable. This dependency is currently locked to 3.0.0.

**Recommendation:** The upstream dependency since version 3.4.0 has the necessary changes implemented and should be compatible with the codebase, meeting the needs to run on solc 0.6.x and with the current set of utilized 3.0.0 OZ upgradeable contracts. It is recommended to upgrade to the latest 3.4.2 release, and revert the then unnecessitated vendored dependencies from that PR.

In the future considering checking the latest compatible version, before vendoring dependencies. And even in the case vendoring is needed, for such cases as adding virtual keywords, there may be other projects and good reason to implement it for the entire dependency, therefore considering contributing the change to the dependency itself.

**Goldfinch:**

**Spearbit:**
