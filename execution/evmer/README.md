goliath
=======

The Goliath blockchain is an Ethereum-compatible blockchain with a giant capacity for storage.

## Roadmap.

 - [x] Implement custom EVM with storage backend.
 - [x] Design scheduler-executer.
 - [ ] Basic sequencer.
 - [ ] Schedule txs from sequencer for execution.
 - [ ] Update data model in SQLite to use sequencer timestamp as key.
 - [ ] Test/implement Ethereum RPC node. Deploy Lens protocol as test case.
 - [ ] Deploy entire thing to Google Cloud.
 - [ ] Design an economics model - payment for compute/storage (gas).

## Usage.

```
# Run the sequencer.
./sequencer.sh

# Run the scheduler-executer.
# This listens to the sequencer, and executes txs.
./scheduler-executer.sh --scheduler-db scheduler.sqlite --state-db state.sqlite

# Run the ETH RPC node.
./rpc.sh

# Submit txs to the ETH RPC node.
cast send asdasdasd
```

## How does it work?

### Background.

In a smart contract blockchain, sequencing, execution and storage are all tightly coupled together on each node. 

 1. **Sequencing** - submitting a tx to the mempool, and then ordering it in a block.
 2. **Execution** - running the VM state transition for a transaction. `S(t+1) = Y(S(t), T)`, where `S(t)` is the state at time `t`, `Y` is a state transition fn, `T` is the transaction.
 3. **Storage** - the state (`S`) of the chain - accounts, code, and contract storage.

Because these are all tightly coupled, it's really quite impossible to scale any individual subsystem. Rollups made the first step here, in moving execution and storage off of the L1 chain and onto "L2". Rollups are secure because the L2's execution is implemented inside the L1's VM, [and fraud can be proven](https://github.com/ethereum-optimism/cannon) - meaning you can use cryptoeconomic stakes to incentivise the L2 operator not to defraud users. But they still have the same limits on storage and throughput.

Now, rollups could scale storage by putting it on a cloud database, right? What would be the problem here? Well, to start with - that's not decentralized. Anyone could modify the database, take it down, etc. You **would** be able to verify this happening though - running a local node, you could detect such faults, **as long as you had the list of all transactions up until that point**. 

What's interesting here is that with only a transaction sequence, we can maintain verifiability. Imagine we extract the sequencing away from our hypothetical rollup's `geth`, into a separate service - called the **sequencer**. The sequencer is really a minimum viable blockchain - given an ordered list of transactions, anyone can execute them locally, and verify the state. So long as the sequencing service is byzantine-fault tolerant (meaning nodes can fail, maliciously or not, and keep working), the blockchain has some degree of decentralization. Which is easy, because we already have Tendermint BFT.

So, given a decentralized sequencer, we're really free to build our execution layer however we want. We could build a protocol that distributes execution to a set of stakers, and they all use stakes and interactive fraud proofs to verify they are doing their job. Or maybe we could use STARK validity proofs, which my [Quark blockchain](https://github.com/liamzebedee/quark-blockchain) design does. But this still isn't really profoundly better than what we have now.

What is profoundly better? **Horizontal scaling of storage.** Right now, we have this clusterfuck of rollups and bridges, because we can't fundamentally increase the capacity of our chains by adding another node - so every time we hit the gas ceiling, we have to diverge and start a new chain. But what if we could scale like Google scales its databases? Then we wouldn't need to go elsewhere - and we wouldn't **lose synchronous composability** either. 

Goliath achieves this using a couple of innovations on top of decoupling - stateless execution, a transactional memory model of state and a storage network. Transactions come from the sequencer and are sent to the executors for processing. The executors run a modified EVM, which reads all state from a distributed storage network. Notably, this is O(1) in time - due to existence of Ethereum [access lists](https://eips.ethereum.org/EIPS/eip-2930) for transactions, we can prefetch the entire input state for a transaction in one network call, as opposed to during the execution itself (which could stall the executor needlessly). Contract state is also designed in a way which preserves data locality, making it cheap to fetch large numbers of storage slots from a single contract, as this only touches at most a few storage nodes. When a transaction finishes, the executor flushes the state leaves that were written to the storage layer. 

Goliath exposes the EVM state as a form of [transactional memory](https://en.wikipedia.org/wiki/Multiversion_concurrency_control) for deployment atop a horizontally-scalable distributed database. The three tries of EVM world state - `(account, code, storage)` - are each extended with an additional dimension of time, which is set as the transaction's sequence number, as well as a commitment to the previous entry. For example, a storage write is an insertion of a row into the `storage` trie with the data `(time, address, key, value)`. This is useful for a couple of reasons. Firstly, it's very easy to reason about and implement historical data access for, as well as pruning of old state into cheaper storage. Secondly, it helps with implementing parallelism in the execution layer. 

The storage and the execution layers are scaled using two different techniques. The storage network is based on Google's Bigtable, and scales via sharding. The execution layer by contrast is scaled via distributed computing. 


> turns out giving up large liveness guarantees to a single actor opens up tons of design space and if you can maintain verifiability it's not even that big a tradeoff for many applications

### Data model.

> "Show me your [code] and conceal your [data structures], and I shall continue to be mystified. Show me your [data structures], and I won't usually need your [code]; it'll be obvious."

```
# Same format as Ethereum transactions.
type tx = (from, to, data)

# The sequencer provides an ordering of execution for all transactions.
sequencer:
    sequences : tx -> seq

# The scheduler listens to transactions from the sequencer,
# and builds a queue for parallel execution.
executer-scheduler:
    latest_sequence : number
    queue : []

# The executer is a STATELESS Ethereum VM.
# Recap: EVM takes state and a transaction, and produces state(t+1).
# The executor outsources its state (reads, writes) to the storage layer.
executer:
    none

# The storage layer stores a complete log of all state for the executer.
# Given a sequence, it can provide the reduced state for that point in time.
storage:
    state -> (sequence) -> (accounts, code, storage)

# The RPC is an Ethereum RPC node, so we can interact with goliath!!!
# It has no state, though it integrates the entire system.
# `eth_call` will call directly to the executor.
# `eth_sendTransaction` will:
# 1) sequence the tx
# 2) listen for the result of execution from the scheduler
rpc:
```

## How to compare blockchain designs?

There are a lot of axes you can compare blockchain designs across:

 * **Storage capacity**. How much data can you access in one transaction? 
 * **Computation capacity**. Called the *gas limit* in Ethereum, how many computational steps can you do in one transaction?
 * **Computation throughput**. Commonly referred to as TPS - how much *gas per second* can your chain process?
 * **Parallelism**. Does your chain run computation in parallel, or is it constrained by processing txs one-by-one? 
 * **Costs for storage and computation**. Based on your chain's architecture and decentralization, the costs of storage and computation will vary.
 * **Decentralization**. Verifiability (via cryptoeconomics, computational methods like replication or STARK proofs), data availability (how long is data available and does that impact who can verify), node requirements (are you targeting data centres or average home PC's).

This design optimizes for storage capacity, computational throughput and parallelism.


