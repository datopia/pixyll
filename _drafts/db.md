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
<li>Inference is the application of reason to histories of facts.</li>
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

<blockquote class="literal">
“Man is certainly stark mad; he cannot make a worm, and yet he will be making gods by dozens.”<br>
<div class="attrib">&mdash; Michel de Montaigne</div>
</blockquote>

Consider a boardwalk lemonade stand in high season,
managed with an earnest commitment to transparency and optimization.  The price
and provenance of every lemon, the yield of each squeeze, hourly ambient
temperatures --- a sample of the _facts_ that our revolutionaries may want to
structure and record into a public, immutable history --- the _memory_ of their
organization, and the substrate for its analytic and inferential
processes.

Blockchain enthusiasts invoke heady problems --- deterministic arbitration,
on-chain governance --- while seldom acknowleding the _explosive_ volumes of
information consumed and emitted by these processes, even within narrow domains.
Platforms without cost-effective stories around the structured retrieval of
historic data are unsuited to all but the most comically trivial class of
information-bound problem: they couldn't govern a lemonade stand.  Unsurprisingly,
businesses solving complex problems already know this.

A
[billion dollar market](https://www.statista.com/statistics/254266/global-big-data-market-forecast/) is
emerging around the private, distributed analysis of append-only logs.
Clearly,
[databases built atop mutable cells](http://www.infoq.com/presentations/Impedance-Mismatch) ---
yesterday's value is obliterated by today's<sup>1</sup> --- are unsuited to many
of the problems faced by their
customers<sup>2</sup>.  [Immutable databases](https://www.datomic.com/) take a
far more interesting position: your structured data's history _is data of the
same order_ --- and ought to be equivalently structured and interrogable.  While
some powerful properties fall out of the obvious design --- auditability,
read-scalability --- we're most keen on the superpowers conferred by the
combination of structured histories
and [declarative logic](https://en.wikipedia.org/wiki/Datalog)<sup>3,4</sup>.

A blockchain's fundamental responsibility is, fortuitously, that of _securing a
coherent, ordered history of facts_ --- just the thing we need, to make
intelligent decisions.  In a truly curious turn, this history --- the network's
_identity_ --- tends, as a matter of [precedent](https://www.ethereum.org/) to
be obscured from decision-making processes.  We've a profusion of platforms with
on-chain data access semantics less expressive than those of an all-nighter BASIC
implementation.  Given the effort and coordination involved in maintaining these
histories, to fail to offer a _transparent_ means of analyzing them --- as a line,
not a point --- is obscenely wasteful and short-sighted.

<div class="footnote">
<span class="small">
<sup>1</sup> While it's tempting to consider traditional databases the
brainchildren of epistemological radicals, the trauma of early 70's data storage
costs has yet to heal.
<br>
<sup>2</sup> Having a passing familiarity with some of these systems, I think
it unlikely much of this usage is recreational.<br>
<sup>3</sup> If you feel your eyes glazing over, resist.
<br>
<sup>4</sup> Not every Hadoop job is better suited to a
public blockchain, or a private immutable database &mdash; the broader point is the
unsuitability of forgetful systems to inferential problems.
</span>
</div>

# How We Got Here


<blockquote class="literal">
“One of the poets, whose name I cannot recall, has a passage, which I am unable at the moment to remember, in one of his works, which for the time being has slipped my mind, which hits off admirably this age-old situation.”<br>
<div class="attrib">&mdash; P.G. Wodehouse</div>
</blockquote>

In the main, blockchains have tended towards composing solutions to consensus,
[Sybil resistance](https://en.wikipedia.org/wiki/Sybil_attack) and replication
 in a manner at odds with the needs of cost and feature-competitive data storage
--- long block times and [exorbitant storage costs](https://medium.com/ipdb-blog/forever-isnt-free-the-cost-of-storage-on-a-blockchain-database-59003f63e01)
being among the more salient consequences.

Significant progress has been made on the above technical concerns --- there are
a number of sound, high-throughput consensus algorithms
(e.g. [metastable](https://ipfs.io/ipfs/QmUy4jh5mGNZvLkjies1RWM4YuvJh5o2FYopNPVYwrRVGV),
[classical](https://tendermint.com), etc.)  composable with responsive,
intuitive mechanisms for Sybil resistance
(POS,
[DPOS](https://bitshares.org/technology/delegated-proof-of-stake-consensus/)).
Elsewhere
([Ethereum](https://github.com/ethereum/wiki/wiki/Sharding-FAQs),
[Filecoin](https://drive.google.com/file/d/0ByEXXlwyI4z7VmR6ejlJeTNZN1E/view)),
novel approaches to state distribution are required for platforms to function at
projected demand.  We have a _vision_ problem, not a technical one.

## First as Tragedy, Then as Farce

From a developer's perspective, one of the more disappointing blockchain trends
is the conflation of information and implementation we've committed to in our
platforms and programming models.  We're recapitulating the wooly-headedness at
the
[center](https://medium.com/@brianwill/object-oriented-programming-a-personal-disaster-1b044c2383ab) of
object-orientation --- even in systems reluctant to describe themselves as such.
Data _isn't_ an implementation detail, and mediating its access through single-use
DSLs<sup>1</sup> is
a [thoroughly debased](https://www.youtube.com/watch?v=-6BsiVyC1kM) strategy at
odds with the needs of
sustainable, [composable](https://www.youtube.com/watch?v=3oQTSP4FngY) systems.

If this seems an abstract concern, consider that the absence of a uniform means
of data interrogation consigns contracts to the
re-implementation<sup>2</sup> of a small set of access patterns over their
"internal state".  While it's awkward to obtain empirical data<sup>3</sup>, we'd
hazard a guess that an astonishing percentage of deployed contracts are
concerned with trivial data brokerage --- compensating for the
shortcomings of their platforms --- rather than doing anything _smart_ or
_contractual_.

<div class="footnote">
<span class="small">
<sup>1</sup> c.f. generated getters and setters per Solidity, etc.<br>
<sup>2</sup> It may surprise you to learn that grave mistakes are often made in these implementations.<br>
<sup>3</sup> Expect a follow-up &mdash; much of what appears as <i>code</i> is data smeared in
lipstick.
</span>
</div>

# A Better Way

<blockquote class="literal left"> “So far it's perfectly simple!... A
galvano-plastic overstress on a centrifugal pin!... A simple matter of
computation!... The factors involved are child's play... Radio-diffusible
lighting with a Valadon projector!... My word, all it takes is a little spunk
and initiative!"  <div class="attrib">&mdash; Courtial des Pereires</div>
</blockquote>

At a high level, our primary interest is in developing a trustless, immutable
database sufficiently expressive to serve as the substrate for a ledger, a
platform for governance, etc. --- without encoding details of those problem
domains into the system's design.

While resilient, autonomous money is a deeply motivating prospect --- one we're
realizing via special purpose systems --- we see blockchain projects kindling
ambitions better served by more general approaches to the modelling and storage
of information.  We'll avoid straying too far into the weeds in this post,
while attempting to sketch a design in which the fundamental interaction --- a
_transaction_ --- denotes something much closer to that word's use in
traditional database systems.

As far as structuring the data itself, we find the [Entity Attribute Value](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model)
model strikes the most effective balance between _open schemas_ and powerful query semantics.
At a high level, data is represented as global triples<sup>1</sup> of the form --- wait for it --- _entity_, _attribute_, _value_.  Four triples (e.g. `joe, age, 72`), visualized
as a property graph<sup>2</sup>:

<center>
<img src="/images/joe-sally.png" style="max-width: 50%; padding: 2ex">
</center>

We embrace the use of [Datalog](https://en.wikipedia.org/wiki/Datalog) --- a
declarative, Turing-incomplete subset
of [Prolog](https://en.wikipedia.org/wiki/Prolog) --- as a domain-specific logic
language for database interrogation.  A trivial Datalog query over the above
data, declared in
Clojure's [literal notation](https://github.com/edn-format/edn):


```clojure
[:find  ?age ?balance
 :where [?e     :friend  ?other]
        [?other :email   "sally@gmail.com"]
        [?e     :balance ?balance]
        [?e     :age     ?age]]
```

Here we're requesting the `age` and `balance` of all entities who possess both
attributes, and are friends with an entity having the `email` _sally@gmail.com_.
Any of the attributes in question may be described by schemas --- structured
data --- concerned with type, cardinality, uniqueness, and, most interestingly,
logical constraints over the attribute's use in transactions.  This latter
property is capable of expressing complex invariants --- such as those
required to maintain a coherent ledger, or enable delegated voting ---
enforcable atop a platform with no _a priori_ knowledge of those problem domains.

<div class="infobox">
<div class="infobox-title">Why Not SQL?</div>
<p>
While both SQL and Datalog are rooted in similar formalisms, in practice, comparison
is confounded by
 <a href="http://blog.schauderhaft.de/2009/06/18/building-a-turing-engine-in-oracle-sql-using-the-model-clause/">implementation-specific extensions</a> &mdash; on both sides &mdash; which may drastically alter the properties of a given system.  Assuming some SQL implementation capable of recursive queries, we'd first
appeal to Datalog on the basis of expressive power: it's far less <i>operational</i> (<i>what</i>, rather than <i>how</i>), inferentially succint, and amenable to structural query representation.
</p>
<p>

</p>
</div>


EAV is well suited to domains involving a voluminous set of attributes sparsely
associated with entities --- e.g. an open system with user-defined attribute
schemas.  When modelling immutable data, we'll be dealing with EAVT quads
(_Entity, Attribute, Value, Time_ --- though we can put this aside for the
moment).

<div class="footnote">
<span class="small">
<sup>1</sup> Some EAV databases organize triples within named tables &mdash; we don't find
tables to be a motivating organizational scheme.<br>
<sup>2</sup> <i>Sally</i> is a first-class entity &mdash; in practice, the <i>value</i> of Joe's <code>friend</code> attribute would be Sally's entity ID.
</span>
</div>


From a thousand paces, a distributed ledger appears as a special-purpose
database , with implicit invariants and an inflexible structure.  While
resilient, autonomous _money_ is a deeply motivating goal, systems are evolving
in directions necessitating a more unified approach to modelling and storage.
One way of getting a handle on this may be to discuss a system in which
_transaction_ denotes something much closer to its usage in traditional
databases.


How might we flexibly support value transfer in such a system?  If our fundamental
interaction is the submission of arbitrary, structured data, let's
examine an idealized transaction, represented as a vector of two facts:

```clojure
'[{:simoleon/balance (- 99),
   :datopia/entity   <sender>},

  {:simoleon/balance (+ 99),
   :datopia/entity   <recipient>}]
```

Does the system need to understand, _a priori_, the implications of the above
data?  We could eliminate this special-casing if --- at the point attributes are
declared --- we provide a means of declaring logical propositions which much (`transfer/from`, etc.) consisted of an on-chain schema, optionally
augmented with logical constraints --- a problem parameterized over the
transaction data, and, optionally, incorporating the results of a query
(e.g. yielding the current Simoleon balance of `<sender>`) against the
database/chain.  If we're unable to unify all of the problems, associated with
the transaction's attributes, we reject it --- otherwise it's considered valid
and included in the block.

# Proposed Semantics

Talk about why structure at all

## The Tyranny of Structurelessness

We find the [Entity Attribute Value](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model)
model strikes an effective balance between _open schemas_ and flexible query semantics.
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
