---
layout: post
title:  Blockchains and Immutable Databases
author: Moe Aboulkheir
summary: Blockchains positioned as application deployment targets must confront the ubiquity of highly-structured information in all but the most trivial applications.  Expensive, crude or ad-hoc approaches to modelling, storing and retrieving data are typical in the blockchain space.  This need not be the case.
---

# Axioms

<blockquote>
<ol>
<li>A blockchain is a history of facts.</li>
<li>Inference is the application of reason to facts.</li>
</ol>
</blockquote>

# Motivation


<!--
This article is focused on the consequences of the above two banalities, when
considered in concert.
There appears to be a widespread determination to avoid considering the
synthesis of the above two banalities --- even among those aspiring to
solve problems as expansive and history-bound as computational arbitration and
on-chain governance.

What kind of power and _reach_ do we expect will
emerge from [computation protocols](http://ethdocs.org/en/latest/introduction/what-is-ethereum.html)
in which the [affordable](https://medium.com/ipdb-blog/forever-isnt-free-the-cost-of-storage-on-a-blockchain-database-59003f63e01)
set of on-chain data access patterns compares unfavourably with those of an all-nighter
BASIC implementation?-->

Consider a boardwalk lemonade stand in high season (87&deg;, limp windsock),
managed with an earnest commitment to transparency and optimization.  The price
and provenance of every lemon, the yield of each squeeze, hourly ambient
temperatures --- a sample of the facts these ideologues would likely want to
structure and record into a public, immutable history --- the _memory_ underpinning
all higher-order inferential processes.

It is obscene and disingenuous to invoke lofty problems --- computational
arbitration, on-chain governance --- without acknowledging that these processes
consume and emit explosive volumes of information, even in apparently simple
cases.  A platform without a good story around structured, transparent, cost-effective
historic data retrieval is unsuited to all but the most comically trivial class
of inferential problem on-chain.

A
[billion dollar market](https://www.statista.com/statistics/254266/global-big-data-market-forecast/) is
emerging around the private, distributed processing of append-only logs.
Clearly, databases built around mutable cells --- yesterday's value is
obliterated by today's --- are unsuited to many of the problems faced by their
customers.  [Immutable databases](https://www.datomic.com/) can represent
effective and elegant alternatives --- the history of your data is _also data_,
and perhaps ought to be be equivalently structured and interrogable.

The primary responsibility of a blockchain is that of securing coherent, ordered
histories of facts, yet this _history_, the network's principal asset --- is
often dropped on the floor in on-chain computation protocols which privilege the
current block height and expose extremely crude mechanisms for explicit fact
representation, via data structures which cannot efficiently be queried.

Blockchains are _already_ in the immutable data storage business.  We ought to at
least consider the trade-offs involved in structuring, exposing and interrogating
these timelines --- rather than obscuring them.

# How We Got Here


<blockquote class="literal">
“One of the poets, whose name I cannot recall, has a passage, which I am unable at the moment to remember, in one of his works, which for the time being has slipped my mind, which hits off admirably this age-old situation.”<br>
<div class="attrib">&mdash; P.G. Wodehouse</div>
</blockquote>

In the main, blockchains have tended towards composing solutions to consensus,
[Sybil resistance](https://en.wikipedia.org/wiki/Sybil_attack) and replication
 in a manner at odds with the needs of cost-competitive, structured data storage
--- long block times and [exorbitant storage costs](https://medium.com/ipdb-blog/forever-isnt-free-the-cost-of-storage-on-a-blockchain-database-59003f63e01)
being among the more salient consequences.

Concordantly, the blockchain elevator pitch --- _a distributed, immutable ledger_ ---
doesn't admit the possibility that ledgers are, in practice, parochial and inflexible
databases with strict invariants.

Significant progress has been made on the above technical concerns --- there are a number
of sound, high-throughput consensus algorithms (e.g. [Avalanche](https://ipfs.io/ipfs/QmUy4jh5mGNZvLkjies1RWM4YuvJh5o2FYopNPVYwrRVGV),
[Tendermint](https://tendermint.com), etc.)  composable with responsive, intuitive
mechanisms for Sybil resistance (POS, [DPOS](https://bitshares.org/technology/delegated-proof-of-stake-consensus/)).  Elsewhere
([Ethereum](https://github.com/ethereum/wiki/wiki/Sharding-FAQs),
[Filecoin](https://drive.google.com/file/d/0ByEXXlwyI4z7VmR6ejlJeTNZN1E/view)), novel approaches to state distribution
are required for platforms to function at projected demand.  We have a _vision_ problem,
not a technical or economic one.

# Proposed Semantics

Talk about why structure at all

## The Tyranny of Structurelessness

We find the [Entity Attribute Value](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model)
model strikes the most effective balance between _open schemas_ and powerful query semantics.
At a high level, data is represented as global triples<sup>1</sup> of the form --- wait for it --- _entity_, _attribute_, _value_.  Four triples (e.g. `joe, age, 72`), visualized
as a property graph<sup>2</sup>:

<center>
<img src="/images/joe-sally.png" style="max-width: 50%; padding: 2ex">
</center>

EAV is ideal in domains where a voluminous set of attributes are sparsely associated
with entities --- e.g. an open system with user-defined attribute schemas.

<div class="footnote">
<span class="small">
<sup>1</sup> Some EAV databases organize triples within named tables &mdash; we don't find
tables to be a motivating organizational scheme.<br>
<sup>2</sup> <i>Sally</i> is a first-class entity &mdash; in practice, the <i>value</i> of Joe's <code>friend</code> attribute would be Sally's entity ID.
</span>
</div>

### Querying

We've a high degree of flexibility in the access patterns supported by a typical
implementation of a triple store (`3!` indices --- EAV, AEV, ...).  While we may
 enumerate ranges of individual indices --- to express e.g. _all attributes & values of some
entity_ --- we may also consider them in concert as the storage layer of a general purpose, deductive query engine.  Let's!

We embrace the use of [Datalog](https://en.wikipedia.org/wiki/Datalog) ---
a declarative, Turing-incomplete subset of [Prolog](https://en.wikipedia.org/wiki/Prolog) --- as a domain-specific logic
language.

A trivial Datalog query over the above data, declared in Clojure's [literal notation](https://github.com/edn-format/edn):


```clojure
[:find  ?age ?balance
 :where [?e     :friend  ?other]
        [?other :email   "sally@gmail.com"]
        [?e     :balance ?balance]
        [?e     :age     ?age]]
```

Here we're requesting the `age` and `balance` of all entities who possess
both attributes, and are friends with an entity having the `email` _sally@gmail.com_.

While the above expression may bear passing similarities with the equivalent SQL,
it's operating in a radically different paradigm --- [first-order logic](https://en.wikipedia.org/wiki/First-order_logic).
We represent
a [unification problem](https://en.wikipedia.org/wiki/Unification_(computer_science)) in terms of our data model, and interrogate the database for
the set of substitions.

If your curiosity is unsatisfied by this example, there exist [decades of high-quality literature](https://scholar.google.com/scholar?hl=en&q=datalog)
on Datalog's properties and implementation, and [a variety of contemporary applications](https://en.wikipedia.org/wiki/Datalog#Systems_implementing_Datalog) you might consult for inspiration.

## A Brief History of Time

As alluded to earlier, structured storage has favoured mutable cells:
yesterday's value is obliterated by today's.  While it's often possible --- and
occasionally convenient --- to build coherent systems atop these semantics
alone, doing so in a blockchain context makes little sense.  Fortunately, there
exist awesomely powerful alternatives, in the form of immutable databases.

<div class="thumbnail-right" style="width: 300px">
<img src="/images/immutable.png">
</div>
In his talk on
[Datomic](https://www.datomic.com/), [The Database as a Value](https://www.youtube.com/watch?v=EKdV1IgAaFc),
Rich Hickey appeals to the intuitive properties of an _epochal model of time_ --- an
unambiguously ordered accretion of immutable facts --- as a more coherent basis
for reasoning about database semantics than the prevailing mutable-cell model.
While [MVCC](https://en.wikipedia.org/wiki/Multiversion_concurrency_control) is
used pervasively in (cell-based) relational databases for read scaling and snapshot isolation,
immutable databases are multi-version all the way down.

We can model this property by conceiving of our EAV triples as EAVT quads,
incorporating a dimension we'll call, uh, _time_:

<table class="small ops entity" cellpadding="0" cellspacing="0" style="margin-bottom: 2ex">
<thead>
<tr>
<td>Entity</td>
<td>Attribute</td>
<td>Value</td>
<td>Time</td>
</tr>
</thead>
<tbody>
<tr>
<td>"joe"</td>
<td>balance</td>
<td>27</td>
<td>0</td>
</tr>
<tr>
<td>"sally"</td>
<td>balance</td>
<td>1</td>
<td>0</td>
</tr>
<tr>
<td>"joe"</td>
<td>balance</td>
<td>26</td>
<td>1</td>
</tr>
<tr>
<td>"sally"</td>
<td>balance</td>
<td>2</td>
<td>1</td>
</tr>
</tbody>
</table>

This approach ought to be uncontroversial among blockchain enthusiasts ---
consider a network attaining consensus over a single numerical value, _v_, for
4 successive blocks:

![time](/images/blockchain.png)

From no perspective is there a meaningful answer to _what is the value of v?_ which
doesn't incorporate the block height, or some other value equivalent to the `T` discussed above.
The insight gleaned from systems like Datomic is that this needn't be some inconvenient
 fact --- we gain tremendous expressivity and leverage by embracing
it wherever we reason about information.
