https://gist.github.com/TCHKVSKY/65451ae1d6a0c83658f291af4ce43580

### critical = 0 high = 0 medium = 0 low = 2 gas_optimization = 1 informational = 4 total = 7

---

## Low Risk

### `UniqueIdentity` - Missing withdrawal function for the token mint fee charged

**Severity:** _Low Risk_

**Context:** [UniqueIdentity.sol#L96](https://github.com/warbler-labs/mono/blob/e863eb4b0662771bc83204cde33e86a4964e6ac3/packages/protocol/contracts/protocol/core/UniqueIdentity.sol#L96)

**Description:** The `_mintTo` function charges a `MINT_COST_PER_TOKEN` fee to end-users to cover associated KYC costs. The contract thereby receives value, however, there is no withdrawal function implemented within the current version to allow this accruing balance to be accessed.

**Recommendation:** Implement a privileged withdraw function with supporting role, slated for a future contract version to access this balance.

**Goldfinch:**

**Spearbit:**

### `UniqueIdentity` - Potential front running / replay attack vectors

**Severity:** _Low Risk_

**Context:** [UniqueIdentity.sol#L15](https://github.com/warbler-labs/mono/blob/e863eb4b0662771bc83204cde33e86a4964e6ac3/packages/protocol/contracts/protocol/core/UniqueIdentity.sol#L15)

**Description:**

1. `UniqueIdentity` uses nonces to identify signatures uniquely but the structure of the signed data is identical for `mint` and `burn`. This effectively positions the signer as a trusted single point of failure. Let's consider the scenario where the signer has generated two different signatures meant for the `mint` function, for Alice (with nonces 0,1 respectively). Assuming the second signature was somehow leaked to Eve (the attacker), and that Alice has already used the first one to mint a UID, Eve can now use the second one to burn Alice’s UID without her consent.

2. `UniqueIdentity#burn` can be called by anyone with a valid signature on behalf of someone else, which opens up a potential front-running issue. Let's say Alice (could be a contract/EOA) has a UID she wishes to burn. Alice is transmitting the `burn` transaction which gets front-runned (as is) by someone else, causing her transaction to fail (while the first transaction runs successfully), which (depends on Alice's client logic) may cause a false sense of failure for the entire burning process.

**Recommendation:**

1. Consider adding the function signature (also known as the 4 bytes identifier) to the hash preimage to distinguish between signatures meant for `mint` and `burn`.
2. The off-chain logic used for interaction with the `UniqueIdentity` contract should take the described scenario into consideration and handle this type of transaction failure properly.

**Goldfinch:**

**Spearbit:**

<br>

## Gas Optimization

### Gas optimizations

**Severity:** _Gas Optimization_

**Context:**

1. [UniqueIdentity.sol#L111-112](https://github.com/warbler-labs/mono/blob/e863eb4b0662771bc83204cde33e86a4964e6ac3/packages/protocol/contracts/protocol/core/UniqueIdentity.sol#L111-L112)

**Description:**

1. `UniqueIdentity#burn` - The check to validate that the balance has to be 0 after burning is redundant. Assuming that there are no accounts with an id balance > 1 caused by previous code versions, a user balance for a specific `id` can be either 0 or 1. The `_burn` call will either burn exactly 1 token or revert, and there's no external call that can cause unwanted behavior with reentrancy, thus `accountBalance` has to be 0, and the check is redundant.

**Goldfinch:**

**Spearbit:**

<br>

## Informational

### Signer key leak risk in case of ECDSA signing nonce leak or nonce re-use by black box signer

**Severity:** _Informational_

**Context:** [UniqueIdentity.sol#L138-L140](https://github.com/warbler-labs/mono/blob/august-audit/packages/protocol/contracts/protocol/core/UniqueIdentity.sol#L138-L140)

**Description:** The off-chain signer depends upon OpenZeppelin Defender which utilizes AWS KMS as a keystore and for cryptographic operations. Based on preliminary research, the HSM in use is certified but the ECDSA certifications explored appear to state they are simply conformance tests to ensure correct implementation of the algorithm but make no testatments necessarily to the security of the cryptographic processes.

In the case of a signing nonce leak (k), where the black box either predictably chooses a nonce, or leaks the one used with an accompanying signature, the private key used and stored could be obtained.

Similarly, if a signing nonce (k) is ever re-used for signing 2 different messages, the 2 resulting signatures could be used to obtain the signing key.

**Recommendation:** Using audited and open-source solutions is most ideal, where the signing nonce worries can be put to rest. The black box in question is not open-sourced, however, it is still among the best options in the market for teams not looking to have their own on-site key security logistics. The Goldfinch team should reach out to the service providers in question and ensure they have appropriate measures in place on the HSMs to avoid these potential risks, with most of both being solvable by RFC6979.

**Goldfinch:**

**Spearbit:**

### Carefully set and utilize long time constants depending on their application

**Severity:** _Informational_

**Context:** [Accountant.sol#L29](https://github.com/warbler-labs/mono/blob/august-audit/packages/protocol/contracts/protocol/core/Accountant.sol#L29)

**Description:** The line in question sets a `SECONDS_PER_YEAR` constant, which does not account for leap years, and would eventually go out of synchronicity with a calendar if used for such a purpose. The solidity `years` literal was removed in a previous version due to the confusion arising as to whether it should or should not account for leap years https://docs.soliditylang.org/en/v0.6.9/050-breaking-changes.html#literals-and-suffixes.

**Recommendation:** In this case, a change is not recommended, as the `Accountant` contract appears to utilize a Actual/365 Basis for interest accrual, in which case using exactly 365 days based on 86400 second days without account for non-leap years should be fine. This informational issue is being brought up to be careful in regards to other potential uses of such time constants across the protocol so as to be careful whether leap years should be accounted for to keep synchronicity, and to ensure consistency of such constants when used for accounting.

**Goldfinch:**

**Spearbit:**

### `Go` - Prefer stricter relational operators where possible

**Severity:** _Informational_

**Context:** [Go.sol#L98](https://github.com/warbler-labs/mono/blob/august-audit/packages/protocol/contracts/protocol/core/Go.sol#L98), [Go.sol#L105](https://github.com/warbler-labs/mono/blob/august-audit/packages/protocol/contracts/protocol/core/Go.sol#L105)

**Description:** The `goOnlyIdTypes` function queries the UID token balances of entities attempting to interact with it, but it accepts any balance greater than zero, while the only valid possible values are either 0 or 1 for the current implementation.

**Recommendation:** Utilize a stricter equality check of 1 instead, which signals a valid contained `UniqueIdentity`. This is both safer in the case of some unforeseen changes happening to `UniqueIdentity` and is more inline with the specification, where values greater than 1 would not be valid and should not be considered as such in the code.

**Goldfinch:**

**Spearbit:**

### `UniqueIdentity` - Unused digital signatures will be practically revoked once the signer was removed

**Severity:** ֿ*Informational*

**Context:** [UniqueIdentity.sol#L140](https://github.com/warbler-labs/mono/blob/e863eb4b0662771bc83204cde33e86a4964e6ac3/packages/protocol/contracts/protocol/core/UniqueIdentity.sol#L140)

**Description:**
Signatures that were given through the RPC but were not used before the signer was removed will be practically revoked.
**Recommendation:**
Make sure that the off-chain signer logic supports the scenario described above.
**Goldfinch:**

**Spearbit:**
