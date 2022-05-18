quark
=====

A decentralized state machine that can transfer 1,000,000 unique tokens on Uniswap in a single atomic transaction. How?

 * **UXTO-like storage**. Transactions only lock the parts of state they modify, there is no global state lock like in EVM.
 * ...**distributed**. Instead of every node storing the entire state, we partition the data in the same way Google's Bigtable/Spanner scales to trillions of rows. 
 * ...**decoupled from execution**. STARK proofs are the answer - self-contained transactions that prove the storage leaves they updated, in `O(log N)` time. 

## Background.

 * [Multi-version concurrency control](https://en.wikipedia.org/wiki/Multiversion_concurrency_control).
 * [Transactional memory](https://en.wikipedia.org/wiki/Transactional_memory).
 * Google Bigtable - horizontal sharding via sorting by key and partitioning on row range.
 * Google Spanner - TrueTime API.
 * Bitcoin - POW/difficulty as a BFT clock - compared against TrueTime.
 * State models - UXTO (parallelisable), account-based - akin to a global interpreter lock.
 * Models of computation - replicated state machines, verifier-prover.

## Comparison.

There are many axes you can compare blockchains against:

 * **Transactional bandwidth**: how much compute units (gas) of capacity does that chain offer to process per second? Is the memory model amenable to parallelisation (UXTO, Solana)?
 * **Storage costs and limits**: how much does persistent storage cost? In nearly every chain (BTC, EVM, SOL), every node must store the entire system state, which makes storage extremely expensive.
 * **Execution costs and limits**: how much does execution/compute cost? In nearly every chain, every node must run the full transaction for O(N) cost. In STARK/SNARK systems, execution cost is generally O(log^2 N). 
 * **Scalability**: when the chain reaches the limits of storage/execution, how do you scale further? **Bridges are the ugliest solution**. IBC works only marginally better. Neither are **atomically composable** - it is always worse to interact cross-chain than it is to interact within the chain. 

