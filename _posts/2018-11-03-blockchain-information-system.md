---
layout: post
title:  Blockchains as Information Systems
author: Moe Aboulkheir
summary: Blockchains positioned as application deployment targets must confront the ubiquity and volume of highly-structured information in all but the most trivial applications.  Expensive, crude or ad-hoc approaches to modeling, storing and retrieving data are typical in the blockchain space.  This need not be the case.
tags: blockchain database vision
---

# Axioms

1. A blockchain is a history of facts.
2. Inference is the application of reason to histories of facts.

# Goals

<blockquote class="literal">
An integrated set of components for collecting, storing, and processing data and for providing information, knowledge, and digital products.
<div class="attrib">
&mdash; Zwass, Vladimir. "Information system." <a href="https://www.britannica.com/topic/information-system">The Encyclopedia Britannica.</a>
</div>
</blockquote>

Below, we'll attempt to convince you that neither traditional databases nor
blockchains represent epistemologically robust _information systems_ --- the
former forgets, the latter is often unable to remember when it
counts<sup>1</sup>.  More consequentially, we'll suggest that sound information
systems are a prerequisite for solving many of the problems which engage us as a
community.

Through unceasing appeal
to
[immutable databases](http://scale-out-blog.blogspot.com/2014/02/why-arent-all-data-immutable.html) as
solution space from which we've plenty to learn, we hope to establish that it's
both possible and necessary to offer comparable facilities in a permissionless,
distributed information system.  In parallel, we'll suggest that "smart
contracts" often function in practice as gatekeepers for data, which may
otherwise be directly read or conditionally written --- if only there existed a
generic mechanism for modelling, interrogating, permissioning and storing
_structured histories of values_.

Finally, we'll make a case that user-schematized attributes --- with optional,
logical constraints over their usage --- may represent a simpler and more
expressive means of talking about data than ad-hoc key value stores and serial
imperatives.  By enforcing write constraints, apparently fundamental logical
invariants (those around asset transfer, say) may be excised from the core of
the system, while being trivially implementable atop it.  Our contention is that
the resulting environment --- in which data is collaboratively modelled, freely
shared and uniformly accessed --- approaches an ideal substrate for
transparently tackling complex analytic and inferential problems.

<div class="footnote">
<span class="small">
<sup>1</sup> By, say, emulating "mutable cell" storage semantics in on-chain computation protocols, surfacing only the most recently committed value for each cell &mdash; requiring that histories be
maintained explicitly, expensively, and in data structures immune to efficient or expressive interrogation.</span>
</div>


# Motivation


<blockquote class="literal">
“Man is certainly stark mad; he cannot make a worm, and yet he will be making gods by dozens.”<br>
<div class="attrib">&mdash; Michel de Montaigne</div>
</blockquote>

Consider a boardwalk lemonade stand in high season, managed with a commitment to
transparency and self-optimization.  The price and provenance of every lemon,
the yield of each squeeze, hourly ambient temperatures --- a sample of the
_facts_ that our revolutionaries may want to structure and record into a public,
immutable history --- the _memory_ of their organization, and the substrate for
its analytic/inferential processes.

Blockchain enthusiasts invoke heady problems --- deterministic arbitration,
on-chain governance --- while seldom acknowledging the _explosive_ volumes of
information consumed and emitted by these processes, even within narrow domains.
Platforms --- blockchains, or otherwise --- without cost-effective solutions to
structured, historic data retrieval are suited only to the most comically
trivial class of problem: _they couldn't govern a lemonade stand_.
Unsurprisingly, businesses solving complex problems already know this.

<blockquote class="literal left">
“A database that updates in place is not an information system.  I'm sorry."<br>
<div class="attrib">&mdash; Rich Hickey, The Database as a Value</div>
</blockquote>

A
[billion dollar market](https://www.statista.com/statistics/254266/global-big-data-market-forecast/) is
emerging around the private, distributed analysis of append-only logs.
Clearly,
[databases built atop mutable cells](http://www.infoq.com/presentations/Impedance-Mismatch) ---
yesterday's value is obliterated by today's --- are unsuited to many of the
problems faced by their
customers.  [Immutable databases](https://www.datomic.com/) take a
far more interesting position: your structured data's history is data _of the
same order_ --- equivalently structured and interrogable. When the architectural
predecessors of contemporary databases were conceived in the early 1970s, this
approach would've
been
[ostentatious in the extreme](https://www.computerworld.com/article/3182207/data-storage/cw50-data-storage-goes-from-1m-to-2-cents-per-gigabyte.html).  Fortunately, an _awful_ lot has happened to
the price of storage media in the intervening decades<sup>1</sup>.

<blockquote class="literal"> “Peter had seen many tragedies, but he had
forgotten them all.”  <div class="attrib">&mdash; J.M. Barrie, Peter Pan</div>
</blockquote>

Fortuitously, a blockchain's fundamental responsibility is that of securing a
coherent, immutable, ordered history of facts. Just the thing we need, to make
intelligent decisions!  In a truly curious turn, this history --- the network's
_identity_ --- tends, as a matter of [precedent](https://www.ethereum.org/), to
be obscured from on-chain computation protocols determined to privilege the
present.  Given the effort and coordination involved in maintaining these
histories, to fail to offer a _transparent_ means of analyzing them --- as a
line, not a point --- is astonishingly profligate and short-sighted.

<div class="footnote">
<span class="small">
<sup>1</sup> In late 2018, we can get for <a href="https://www.amazon.com/Elements-Portable-External-Drive-WDBU6Y0020BBK-WESN-x/dp/B0713WPGLL/ref=sr_1_1_sspa">$99</a> what would've cost three quarters of a billion dollars in the early 70s.
</span>
</div>

# How We Got Here


<blockquote class="literal">
“One of the poets, whose name I cannot recall, has a passage, which I am unable at the moment to remember, in one of his works, which for the time being has slipped my mind, which hits off admirably this age-old situation.”<br>
<div class="attrib">&mdash; P.G. Wodehouse</div>
</blockquote>

In the main, blockchains have tended towards composing solutions to
consensus, [Sybil resistance](https://en.wikipedia.org/wiki/Sybil_attack) and
replication in a manner at odds with the needs of cost and feature-competitive
data storage --- long block times
and
[exorbitant storage costs](https://medium.com/ipdb-blog/forever-isnt-free-the-cost-of-storage-on-a-blockchain-database-59003f63e01) being
among the more salient consequences.  The pervasive use of the word _ledger_ ---
unaccompanied by the concession that ledgers are special-purpose databases ---
has likely cemented our aversion to considering blockchains as _information
systems_, in any broad sense.

Significant progress has been made on the above technical concerns --- less on
the cultural ones.  On the solutions side, there exist a number of sound,
high-throughput consensus algorithms
(e.g. [metastable](https://ipfs.io/ipfs/QmUy4jh5mGNZvLkjies1RWM4YuvJh5o2FYopNPVYwrRVGV),
[classical](https://tendermint.com), etc.) composable with responsive, intuitive
mechanisms for Sybil resistance
(POS,
[DPOS](https://bitshares.org/technology/delegated-proof-of-stake-consensus/)).
Elsewhere
([Ethereum](https://github.com/ethereum/wiki/wiki/Sharding-FAQs),
[Filecoin](https://drive.google.com/file/d/0ByEXXlwyI4z7VmR6ejlJeTNZN1E/view)),
novel approaches to state distribution are required for platforms to function at
projected demand.  We've a _vision_ problem, not a technical one.


## First as Tragedy, Then as Farce

From a developer's perspective, one of the more disappointing _compute_
blockchain trends is the conflation of information and implementation at the
center of the dominant programming model.  We're recapitulating
the
[worst](https://medium.com/@brianwill/object-oriented-programming-a-personal-disaster-1b044c2383ab) of
object-orientation, atop systems embarrassed to describe themselves as such.
Data isn't an implementation detail, and mediating its access through
domain-specific _methods_<sup>1</sup> is
a [thoroughly debased](https://www.youtube.com/watch?v=-6BsiVyC1kM) strategy at
odds with the needs of
sustainable, [composable](https://www.youtube.com/watch?v=3oQTSP4FngY) systems.

These aren't stylistic concerns. The absence of a fundamental means of global,
structural interrogation/insertion consigns contracts to the
re-implementation<sup>2</sup> of a small set of access patterns over their
"internal state" --- whatever that means, and however it's been jerry-rigged
together.  While it's awkward to obtain empirical data<sup>3</sup>, we've the
intuition that an astonishing percentage of deployed contracts are concerned
with trivial, imperative data brokerage ---
compensating for the shortcomings of their platforms, not doing anything
_smart_.  Briefly, an excerpt
from
[Solidity by Example](https://solidity.readthedocs.io/en/v0.4.24/solidity-by-example.html):

```js
contract Ballot {
  ...
  mapping(address => Voter) public voters;
  ...
  function giveRightToVote(address voter) public {
    require(msg.sender == chairperson,
            "Only chairperson can give right to vote.");
    require(!voters[voter].voted,
            "The voter already voted.");
    require(voters[voter].weight == 0);
    voters[voter].weight = 1;
  }
  ...
}
```

This is fairly typical Solidity code --- after an imperative sequence of runtime
assertions, the `giveRightToVote` method sets a nested, persistent property to
`1`. All of the other methods on the `Ballot` object are in a similar line of
work --- delicate, sequential assertions, followed by trivial data manipulation.
This is not code, it's data disguised by blush and carmine.

<div class="footnote">
<span class="small">
<sup>1</sup> c.f. generated getters and setters per Solidity, etc.<br>
<sup>2</sup> It may surprise you to learn that grave mistakes are often made in these implementations.<br>
<sup>3</sup> Expect a follow-up.
<br>
</span>
</div>

# A Better Way

<blockquote class="literal left"> “So far it's perfectly simple!... A
galvano-plastic overstress on a centrifugal pin!... A simple matter of
computation!... The factors involved are child's play... Radio-diffusible
lighting with a Valadon projector!... My word, all it takes is a little spunk
and initiative!"  <div class="attrib">&mdash; Courtial des Pereires</div>
</blockquote>

At a high level, our principal interest is in developing a trustless, immutable,
deductive _information system_, sufficiently expressive to serve as the
substrate for a ledger, governance platform, etc. --- without spilling the
details of those domains all over the core system design.  While we'll resist the
impulse to wade too deeply into the weeds in this introductory post, below is a
sketch of a design in which the fundamental network interaction, a
_transaction_, denotes something much closer to that word's use in database
systems.

## The Tyranny of Structurelessness

What follows is a tedious --- but mercifully brief --- exploration of the
requirement of a single, flexible means of structuring arbitrary data
entrusted to the network.

```clojure
;; The angle brackets are an ad-hoc metasyntax for the purpose of
;; abstracting incidental values --- entity identifiers, here.

{:datopia/entity <sally>
 :email          "sally@gmail.com"}
```

Here we've an entity --- a _thing_ --- represented as a map/dictionary, with the
entity's attributes as its keys.  For those of us  unrestrained by
type and struct fetishes, this ought to appear a perfectly familiar, open (i.e. no
fixed set of permissible attributes per entity), universal means of talking
about _things_.  Let's talk about `<sally>` from the perspective of another
entity, `<joe>`:

```clojure
{:datopia/entity <joe>
 :age            72
 :balance        27
 :friend         #:datopia/ref <sally>}
```

<div class="thumbnail-right" style="width: 50%">
<img src="{{ site.url }}{{ site.baseurl }}/images/joe-sally.png" style="padding: 2ex">
</div>

These map representations are trivially isomorphic to
the
[Entity-attribute-value information model](https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model), in
which data is typically structured as global<sup>1</sup> triples of the form
--- wait for it --- entity, attribute, value (e.g. `<joe>, age, 72`).  Like RDF,
without the megalomania.

A key feature of our system is that any of the attributes referenced above may
be (optionally) schematized, to express type, cardinality, uniqueness, or, more
interestingly --- to logically constrain the attribute's use in
transactions.  This latter facility is a general means of establishing global
invariants, such as demanded by a ledger (balance sufficiency, zero-sum
exchange, etc.) --- though far more interesting examples abound.  Users _deploy_
attribute schemas, and the genesis block includes some helpful, primitive
schemas essential to maintain the network itself.

Here's where it gets a little steampunk --- we really
like [Datalog](https://en.wikipedia.org/wiki/Datalog) (an ancient, declarative,
uncannily expressive Turing-incomplete subset
of [Prolog](https://en.wikipedia.org/wiki/Prolog)<sup>2</sup>) as a
domain-specific logic language for database interrogation.  Queries and
invariants, like most everything we traffic in, are structured data.  A trivial
Datalog query over our example data, declared in
Clojure's [literal notation](https://github.com/edn-format/edn), for
readability:


```clojure
[:find  ?age ?balance
 :where [?e     :friend  ?other]
        [?other :email   "sally@gmail.com"]
        [?e     :balance ?balance]
        [?e     :age     ?age]]
```

<span class="small">
All of the bare words / symbols (<code>?</code>-prefixed, by convention) are logic
variables for which we're seeking concrete substitutions.
</span>

On transaction receipt, all applicable attribute invariants are evaluated against an
in-memory Datalog engine, containing only the union of the _facts_ asserted by
the transaction, and the result of an optional, arbitrary _pre-query_ against
the chain state, on which the attribute schema may declare a dependency<sup>3</sup>.  If
the transaction is accepted, its facts are incorporated into the persistent,
authenticated indices which comprise the network's database.  If you've some grasp
of the above query, there's not much mystery to attribute invariants --- they're
simply queries of the same form, required to unify in order for an attribute's
usage --- and any transactions containing it --- to be considered valid.

<div class="infobox">
<div class="infobox-title">Why not SQL?</div>
<p>While both SQL and Datalog are rooted in similar formalisms, in practice, comparison
is confounded by
 <a href="http://blog.schauderhaft.de/2009/06/18/building-a-turing-engine-in-oracle-sql-using-the-model-clause/">
 implementation-specific extensions</a> &mdash; on both sides &mdash; which may
 drastically alter the properties of a given system.  Assuming some SQL
 implementation capable of recursive queries, we'd first
appeal to Datalog on the basis of expressive power: it's far less <i>operational</i>
(<i>what</i>, rather than <i>how</i>), inferentially more succint, and amenable to
structural query representation, per the above example.</p>
<p>
The EAV data model is well suited to domains in which a voluminous set of attributes
are sparsely associated with entities &mdash; e.g. an open system with user-defined attribute
schemas.  While it's certainly possible to use SQL to interrogate EAV-spaces,
it's not our idea of a good time.
</p>
</div>

<div class="footnote">
<span class="small">
<sup>1</sup> Some EAV databases organize triples within named tables &mdash; we don't find
tables to be a motivating organizational scheme.
<br>
<sup>2</sup> Shouts out <a href="https://en.wikipedia.org/wiki/Alain_Colmerauer">Alain Colmerauer</a>.
<br>
<sup>3</sup> e.g. the invariant component of some <code>balance</code> attribute's schema may declare something like <i>"I need the current <code>balance</code> for every entity referenced in the transaction,
in order to evaluate the correctness of the transaction's use of <code>balance</code>".</i>
</span>
</div>


## Facta, non verba

How might we flexibly support value transfer in such a system, in more detail?
As our fundamental interaction is the submission of arbitrary, structured data,
let's idealize a transaction --- in this case, a vector of two facts, each
concerned with a distinct entity:

```clojure
[{:simoleon/balance (- 99),
  :datopia/entity   <sender>},

 {:simoleon/balance (+ 99),
  :datopia/entity   <recipient>}]
```

Here we're imagining Simoleons to be some user-defined asset, which happens to
use the namespace `simoleon` for its qualified keywords<sup>1</sup>.  The
`simoleon/balance` values are submitted not as absolute values, but relative ones
--- we're
declaring something like _&lt;sender>'s `simoleon/balance` shrinks by 99.
&lt;recipient>'s grows by 99_.

To say that Simoleons are a _user-defined asset_ implies only that there exists
a schematized attribute within the network --- `simoleon/balance` --- logically
constraining its own use in such a way as to render inexpressible "unsound
transfers" --- whatever that meant to the author of the attribute's
schema<sup>2</sup>.  Datopia nodes have no intrinsic conception of a
_transfer_ --- when it comes to transaction processing, their primary concern is
the evaluation of user-defined invariants.

Nodes --- prior to applying transactions --- synthesize additional attributes
from low-level metadata not explicitly represented in the transaction's body
(e.g. that its envelope was signed by `<sender>`, rather than `<recipient>` ---
handy).  It's trivial to see that the sum of this data, considered alongside the
transaction --- and a _pre-query_ resulting in `<sender>`'s
`simoleon/balance` --- would be sufficient inputs for a relatively brief logical
declaration of the conditions of value transfer.
It's [first-order logic](https://en.wikipedia.org/wiki/First-order_logic) all
the way down --- Datopia's native asset is defined and exchanged via identical
means.

<div class="footnote">
<span class="small">
<sup>1</sup> An equitable mechanism for granting exclusive access to
particular namespace prefixes &mdash; or fully-qualified attribute names &mdash;
is outside the scope of this post, and perhaps need not be a platform-level feature.
<br>
<sup>2</sup> Semantics no doubt acceptable to those who volunteer to traffic in Simoleons.
</span>
</div>

# The Ecstasy of Immanence

<blockquote class="literal">
<i>Detective Deutsch:</i> What else?
<br><br>
<i>Barton Fink:</i> Trying to think. Nothing, really. He... he said he liked Jack Oakie pictures.
<br><br>
<i>Detective Mastrionotti:</i> You know, ordinarily we say anything you might remember could be helpful. But I'll be frank with you, Fink. That is not helpful.
<div class="attrib">&mdash; Barton Fink (1991)</div>
</blockquote>

It's difficult to conceive of a less attractive transformation than undergone by
systems at the point they develop a dependency on a database.  In the absence of
persistence, functional transformation of _values_ is about as delightful as
software development can get, for many of us.  More often than not, databases invite us to
replace these transparent inputs and outputs with result sets and opaque connection
handles ---  in exchange for the privilege of competing to submit strings to a distant,
volatile authority.

Imagine a network in which we've a class of nodes responsible, in turns, for the
deterministic application of transactions --- and, hopefully, a larger class of
participants issuing transactions, and interrogating the database they
constitute.  With an immutable architecture, participants needn't issue queries
over connection handles, or _issue_ them at all --- we embed a Datalog query
engine in clients, and retrieve authenticated index segments as required by queries
(via a peer-to-peer distribution protocol).  The client maintains as large an
authenticated subset of the network's database / history as it needs, and
executes queries _locally_ --- without contesting shared compute resources<sup>1</sup>.

<div class="footnote">
<span class="small">
<sup>1</sup> For network participants with a need to execute queries
contingent on the consumption of data surplus to local bandwidth/storage capacity &mdash; embedded devices, say &mdash; a generic mechanism for on-chain query evaluation is planned.
</span>
</div>

# A Brief History of Time

For the purposes of convenience, we've been ignoring a crucial dimension --- the
temporal --- and its centrality to coherent information systems.  No longer!
In Rich Hickey's [Datomic](https://www.datomic.com/)
talk [The Database as a Value](https://www.youtube.com/watch?v=EKdV1IgAaFc),
we're beguiled by an appeal to the virtues of an _epochal model of time_ --- an
unambiguously ordered accretion of immutable facts --- as a more sound basis for
reasoning about database semantics than the prevailing mutable cell model.  This
approach ought to be uncontroversial among blockchain enthusiasts --- consider a
network attaining consensus over a single numerical value, _v_, for 4 successive
blocks:

<center>
<img class="center" src="/images/blockchain.png">
</center>

<div class="thumbnail-right" style="width: 300px">
<img src="{{ site.url }}{{ site.baseurl }}/images/immutable.png">
</div>

It doesn't require a philosopher's wit to surmise there's little to discuss
about any of the values of _v_ without reference to the corresponding block
height.  The insight gleaned from systems like Datomic is that the temporality
required by sound information systems needn't be some inconvenience --- we
gain tremendous expressivity and leverage by embracing it wherever we can.

In the abstract, we can model this property by conceiving of our _Entity
Attribute Value_ triples as EAVT quads, incorporating a dimension we'll call,
uh, _Time_:

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
<td>&lt;joe&gt;</td>
<td>balance</td>
<td class="numeric">27</td>
<td class="numeric">0</td>
</tr>
<tr>
<td>&lt;sally&gt;</td>
<td>balance</td>
<td class="numeric">1</td>
<td class="numeric">0</td>
</tr>
<tr>
<td>&lt;joe&gt;</td>
<td>balance</td>
<td class="numeric">26</td>
<td class="numeric">1</td>
</tr>
<tr>
<td>&lt;sally&gt;</td>
<td>balance</td>
<td class="numeric">2</td>
<td class="numeric">1</td>
</tr>
</tbody>
</table>

Each row is an immutable fact --- Joe's balance at T1 doesn't invalidate,
overwrite, or  otherwise supersede his balance _at T0_ (indefinitely
accessible to anyone nostalgic for T0).  This behaviour extends on-chain, where
we might --- for example --- deploy a contract (or execute a query) partly
concerned with transparent, deterministic computations over the full or partial
history of Joe's balance.  Similarly, light clients/applications may express
identical traversals locally, via the selective replication mechanism outlined
above.

Often, we can afford not to care about the temporal dimension ---
such as in the earlier transaction submission examples --- but there are instances
where it's the only means of solving a problem.  We can realize the database at any T,
diff or join two databases as of different times, inspect the history of entities over
time, etc.  These are _superpowers_.

# Project Status

We've a functional, preliminary Clojure testnet
combining [Tendermint's ABCI](https://tendermint.com/) (classical consensus)
with [Datahike](https://github.com/replikativ/datahike)<sup>1</sup>, which, in concert,
can do some --- but not yet all --- of what's described above.  While our
primary focus is the design and delivery of a trustless, permissionless, neutral
deployment of Datopia, we intend to encourage radical arrangements
of its components --- e.g. to experiment with alternative
consensus/Sybil-resistance algorithms, trusted/closed deployments, etc.

Over the course of the next weeks and months, we'll continue to publicly
articulate the project's goals, and technical approach, with a view to attracting
potential contributors, advisors, critics and investors.

<div class="footnote">
<span class="small">
<sup>1</sup> An authenticated <a href="https://github.com/datacrypt-project/hitchhiker-tree">Hitchhiker tree</a> (write-optimized B+ tree) capable of satisfying Datalog queries.
</span>
</div>
