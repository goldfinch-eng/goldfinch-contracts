https://gist.github.com/TCHKVSKY/0cd591dbe7ca2db9b8d8e2f3fe045298

### critical = 0 high = 0 medium = 0 low = 6 gas_optimization = 2 informational = 5 total = 13

---

## Low Risk

### `SeniorPool` - no threshold checks on configurable cancel fee & withdrawal fee could lead to malicious drains

**Context:**
[SeniorPool#L238](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L238)
[SeniorPool#L266](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L266)

**Description:** During withdrawal cancellation or claiming, accompanying fees are charged depending on respective action. These are set in the configuartion and do not appear to have appropriate threshold checks in place, that would prevent the entirety of a user's amount to going to fees instead of withdrawal.

In general, this set of contracts with their configuration are dependent on a trusted, honest and competent operator, which so far the Goldfinch team appears to have done that role, it would however be ideal to minimize potential opportunities and impacts of a malicious operator.

**Recommendation:** Introduce appropriate threshold limits hardcoded into the contract, so the aforementioned configurable fees cannot be used maliciously to drain withdrawing user's balances via claim or cancel.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - initialization of a request's parameter adds value instead of setting it

**Context:** [SeniorPool#L218](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L218)

**Description:** Upon the initialization of a new request within `requestWithdrawal`, the intialization of `fiduRequested` is done by adding any previous value that may have been within that request to the `fiduAmount` argument. This is an anti-pattern for what is meant to be a clean intialization, and could lead to exploit conditions if some method for `_withdrawalRequest` collisions or decrementing of counters associated with them existed or were to be introduced.

**Recommendation:** In our audit analysis, this did not appear to be exploitable under the current implementation, however, it should still be just set to `fiduAmount`, which will save the unnecessary safeMath opcode costs and improve security by reducing the aforementioned attack surface.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - uint256 to int256 unchecked conversion and arithmetic could lead to overflow pre solidity 0.8.x

**Context:** [SeniorPool#L623](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L623)

**Description:** The contract directly typecasts 2 `uint256` types into 2 `int256`. As this contract is on solidity 0.6.12 this could render a silent overflow during conversion, if the `uint256` values exceed `type(uint256).max / 2`, leading to undesired results and potentially further overflow in the arithmetic.

**Recommendation:** Require the `uint256` values being typecast to be equal to or less than `type(uint256).max / 2` to yield values within the safe unsigned range of `int256` to avoid overflow on conversion and arithmetic.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - missing `SafeMath` when solidity 0.6.12

**Context:**
[SeniorPool.sol#L143](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L143)
[SeniorPool.sol#L743](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L743)

**Description:** The contract in question is targeted for solidity version 0.6.12, this specific version does not check and revert for overflows or underflows by default. This can lead to unexpected states and behaviors leading to exploit, especially in the case of user-controlled or influenced input values.

In the case of L143, the value can be immediately overflowed by users. The reversion is only likely to occur due to inherent properties of the `USDC` contract, where the amount needed to overflow is unlikely to ever be available to a user, assuming proper function. Thereby it should fail at the `transferFrom` invocation. However, the origin contract should maximize its own defensive logic rather than depending on assumptions.

**Recommendation:** In just about all cases, except for increments by 1, it is a good idea for pre-0.8 solidity contracts to enforce safe math operations, to match the behavior of "modern solidity".

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - `_applyWithdrawalRequestCheckpoint` may lock user funds in case an existing withdrawal request was not claimed for a long time

**Context:** [SeniorPool.sol#L419](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L419)

**Description:**
USDC Withdrawals are implemented in a two-phase mechanism where the user has to first request a withdrawal and then (in a separate call) claim the USDC available. the call to `claimWithdrawalRequest` will iterate through all the epochs that were not claimed yet, and calculate the available amount of USDC that can be claimed. The for loop that's being used for that might cause the transaction to go out-of-gas, since it contains few storage operations, effectively causing a permanent denial of service, and thus the lock of the user's funds. Based on a pen to paper preliminary tests we have made, it is safe to assume that given the current epoch duration it's highly unlikely that a transaction will go out of gas, however, this issue is still possible and more likely to happen in case of a shorter epoch duration.

**Recommendation:**
Consider adding a function that acts similarly to `_applyWithdrawalRequestCheckpoint` but iterates from `_withdrawalRequests[tokenId].epochCursor` to a specific index determined by the user (it has to be `<= _checkpointedEpochId`). This way, a user experiencing an out-of-gas exception will still be able to withdraw his funds in multiple transactions, thus avoiding the denial of service.

**Goldfinch:**

**Spearbit:**

### `SeniorPool.setEpochDuration` - Missing input validation for `newEpochDuration`

**Context:** [SeniorPool.sol#L101-L112](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L101-L112)

**Description:**
`setEpochDuration` is used by the admin of `SeniorPool` to set the duration of the current and future epochs. `setEpochDuration` does not validate that `newEpochDuration` is greater than zero, which might lead potentially to a denial of service caused by a division by zero inside `_mostRecentEndsAtAfter `.
**Recommendation:**
Consider reverting all calls to `setEpochDuration` with `newEpochDuration = 0`.

**Goldfinch:**

**Spearbit:**

<br>

## Gas Optimization

### `SeniorPool` - events emitting a potentially unnecessary `address(0)` constant

**Context:**
[SeniorPool#L196](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L196)
[SeniorPool#L223](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L223)
[SeniorPool#L252](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L252)

**Description:** These events are emitting a constant `address(0)` value for their kycAddress parameter.

**Recommendation:** Remove this unnecessary parameter and value since it is the same on every event emit and potentially obsolete.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - redundant setting of `request.epochCursor` after `_applyEpochAndRequestCheckpoints` already does it

**Context:** [SeniorPool#L187](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L187)

**Description:** The `epochCursor` for the request in question may be set twice to the same value in the same call. It appears to be redundant and unnecessary, as this second instance only occurs under the precondition that `fiduRequested == 0` for the request. But in all cases, the first instance of appropriately setting the `epochCursor` happens via `_applyEpochAndRequestCheckpoints` via L183 -> L436 -> L427.

**Recommendation:** Remove this redundant setting of the `epochCursor` and its accompanying precondition, which will yield some gas savings during run and deploy.

**Goldfinch:**

**Spearbit:**

<br>

## Informational

### `SeniorPool.cancelWithdrawalRequest` - multiple invocations possible, triggering unnecessary 0-value transfers and event emissions

**Context:** [SeniorPool#L231](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L231)

**Description:** These safeTransfers and events may be emitted unwantonly and multiple times following an initial invocation where a `request.usdcWithdrawable` amount is non-zero. This could be inefficient for legitimate users in terms of gas costs, and a potential griefing vector by malicious users, where they spam multiple valid but useless events from the `SeniorPool` and `Fidu` contracts. Spamming of these events could cause unnecessary additional load on front-ends or other infrastructure dependent on these events.

In general, a cancellation should be a one-shot operation and success should indicate requiring its subsequent deletion and requiring a new withdrawal request be created.

As it stands, using `cancelWithdrawRequest` and `addToWithdrawalRequest` can be used in tandem to effectively modify current request, instead of the former being just oneshot.

**Recommendation:** The easiest solution would be to require `request.usdcWithdrawable` to be 0 before allowing execution of this function. This would yield multiple invocations not possible and make it a truly one-shot operation. The revert error could advise users to claim any unclaimed amounts before they attempt to cancel any of their remaining fidu from that request, rather then allowing potentially even legitimate users to accidently spam the cancel function but not see any effect where their request is actually deleted under specific conditions.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - admin has the ability to set expected future epochs to instead trigger on past times

**Context:** [SeniorPool#L106](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L106)

**Description:** This code under specific conditions may allow the admin to set a `headEpoch.endsAt` that is soon to be reached, back to one in the past, equivalent to the old `_epochDuration`.

If for example the current duration were 2 weeks, and about to be reached, and the new duration were to be set to 1 day, the current epoch expected to end shortly, would instead end 13 days ago. This could in turn, yield `_checkpointEpochId` to be higher at the original `headEpoch.endsAt` than expected.

This means that `headEpoch.endsAt` and expected `_checkpointEpochId` cannot be reliably expected upon with any future date and no past date not exceeding the current `_epochDuration`. In addition, deposits correlated with the new epoch that was checkpointed in the past, could've occurred in a future date compared to its end.

In addition, when it comes to the `setEpochDuration` function, it gives a malicious admin griefing potential to also keep extending epoch's indefinitely so they never trigger. There are trust assumptions across these contracts that depend on an honest and trusted operator, when it comes to these admin functions and general configuration needed for these contracts to work correctly.

**Recommendation:** The fact that no future date cannot be relied upon is a design choice for gas optimization, by allowing for extensions of epochs. However, this lack of finality on past dates for epochs seems to be a potential design flaw. Consider having a precondition here, to only do this specific operation if the new `endsAt` also still at least exceeds or meets the current `block.timestamp`.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - various functions have further restrictable visibility with respect to implementation

**Context:**
[SeniorPool#L101](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L101)
[SeniorPool#L167](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L167)
[SeniorPool#L284](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L284)
[SeniorPool#L553](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L553)
[SeniorPool#L583](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L583)
[SeniorPool#L601](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L601)
[SeniorPool#L655](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L655)
[SeniorPool#L663](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L663)
[SeniorPool#L673](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L673)
[SeniorPool#L684](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L684)

**Description:** A number of functions are declared as public, while never being accessed from an internal source.

**Recommendation:** It is ideal to restrict functions down to their actual implementation. If a function is declared as public, but only ever accessed externally, it should just be external, which also more clearly communicates its use within the implementation, that it is not re-used internally, which is the expectation with a publicly specified function. In the case of the lines noted under Context, they should be set to external.

**Goldfinch:**

**Spearbit:**

### `SeniorPool` - Limited "hijacking" of liquidity in the end of an epoch

**Context:** [SeniorPool.sol#L33](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L33)

**Description:**
While the new proposal prevents the arbitrage opportunity described in the [GIP-25 spec](https://gov.goldfinch.finance/t/gip-25-senior-pool-periodic-withdrawal-requests/1183#summary-2), a mitigated version of it is still possible in the case where an upcoming increase in `usdcAvailable` is about to happen right before the epoch changes. It is important to mention that it will be impossible for a front-runner to complete a withdrawal within a single block, this timing opportunity is only possible in cases where liquidity is added right before an epoch is about to change, and that the main impact of such opportunistic behavior is mainly the shortening of the total time the front-runner will have to wait to withdraw usdc from the system, and the potential temporary delay to other users withdrawal requests.

**Goldfinch:**

**Spearbit:**

### Spec mismatch - Minimum amount request to ignore pro-rata mechanism

**Context:** [SeniorPool.sol#L33](https://github.com/warbler-labs/mono/blob/7ea8714afe86c2d0b095cd05a53eb3149728f950/packages/protocol/contracts/protocol/core/SeniorPool.sol#L33)

**Description:**
[GIP-25](https://gov.goldfinch.finance/t/gip-25-senior-pool-periodic-withdrawal-requests/1183) describes the motivation and the spec for the recent change in `SeniorPool`, however, the requirement that below a certain minimum amount the pro-rata mechanism will be ignored is not implemented.

**Goldfinch:**

**Spearbit:**
