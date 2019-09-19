---
layout: post
title:  Invariants - Smart Contracts distilled
author: Christian Weilbach
summary: Expressing invariants with Datalog provides a powerful smart contract system.
tags: blockchain clojure code Datalog
date: 2019-09-01 12:00:00
---

<!---
Target audience: Technical, CTOs, programming expertise (non-functional), Datalog developers, Investors

Novelty: describe concept well enough for Datalog interests
-->

<blockquote class="literal left"> "The principle of least action is the basic
variational principle of particle and continuum systems. In Hamilton's
formulation, a true dynamical trajectory of a system between an initial and
final configuration in a specified time is found by imagining all possible
trajectories that the system could conceivably take, computing the action (a
functional of the trajectory) for each of these trajectories, and selecting one
that makes the action locally stationary (traditionally called "least"). True
trajectories are those that have least action." 
Principle of Least Action describing invariants in Physics, Scholarpedia
</blockquote>

We have [previously established](/2018/11/03/blockchain-information-system/) the
appeal of a [Datalog based database](https://en.wikipedia.org/wiki/Datalog) in a
blockchain setting. In summary, simplicity must be a [core design
principle](https://www.infoq.com/presentations/Simple-Made-Easy) to manage
complexity in (distributed) information systems. In the following we will lay
out how datopia can be managed by a novel, yet very simple transaction system.
We will first give a motivation for our work and how it relates to other
technologies, then describe its implementation with a simple example and a
real-world accounting contract and finally look at design aspects like cost
models and finally we conclude. Since our concept is useful both in datomic and
datahike, we provide it as a light-weight library that is used by Datopia
instances.


# Motivation

<!---
Motivation from database angle

composable programming model
-->

Almost every contemporary, partially automated social process uses one or more
databases to manage its internal state. These databases often provide powerful
relational logic languages like [SQL](http://www.mysql.com) or
[Datalog](http://datomic.com) to the user. Usually these query languages do most
of the hard work to extract information for a query, efficiently scanning the
large body of accumulated knowledge. The rest of the application is often glue
code to expose the information from the database to the surroundings in form of
user interfaces or APIs and manage access to it. The fact that each database is
contained in a silo that way requires endless, slow and error-prone integration
between different systems.

Datopia instead provides support to selectively load index segments from a swarm
of peers directly into the client-side query engine. Our Datalog query engine
does not distinguish between the data hosted in datopia or locally hosted
private databases in [datahike](https://github.com/replikativ/datahike), in
other words an arbitrary number of databases can be joint at query time at the
reader. The system composes by datalog semantics and the efficiency of its query
planning. [We conceptualize](https://www.youtube.com/watch?v=A2CZwOHOb6U)
Datalog as a universal language for distributed systems. Datopia will therefore
automatically provide a straightforward extended Datalog dialect to extract
information on the client without the need for any intermediary server or client
functionality. Since indices are managed by [immutable data
structures](https://blog.datopia.io/2018/11/03/hitchhiker-tree/) this reading
pattern is totally decoupled and arbitrarily read scalable. [^1]

<!--- Motivation from blockchain angle -->


[^1]: A datahike client replication prototype is working on top of the [dat
    project](https://dat.foundation/) using its publish and subscribe system,
    but we think other variants on [IPFS](https://ipfs.io/) or
    [BitTorrent](http://www.bittorrent.org/) are also possible. It is even
    conceivable with technologies like
    [3df](https://github.com/sixthnormal/clj-3df) that soon most user interfaces
    can be directly filled through an incrementally updating materialized view
    on a client of the database. We are having a collaboration working on
    support for 3df in datahike.
 

# Adding facts to Datopia
 
But what about adding new facts to datopia and changing the database? To supply
an interface to the user with similar ease as the query interface, we would have
to constrain it in a similar way. What if... we would use Datalog also as a
language to just attach an invariant to each relation? Since Datalog is
guaranteed to halt, compact to express against a database of structured fact
triples and in general considered powerful enough to do most application logic,
we can expose our [invariant](https://github.com/datopia/invariant) library
through the datomic or datahike transactor to the network and let users deploy
invariants to the database similarly to smart contract systems like Ethereum. To
be sensible we of course also need to add a public-private key based
identification system and a cost model for the submission of transaction data,
which we will sketch below.

Why is this not possible with off-the-shelf PostgresSQL, CouchDB, MongoDB
datomic or datahike transactor functions or your favorite database? These
databases provide more powerful languages to express transaction operations
because they trust the code of the database is secured by careful manual
safe-guarding of the administrator. Besides being [somewhat
odd](https://www.postgresql.org/docs/current/sql-createfunction.html) to use
programming languages these mechanisms are therefore all Turing-complete, which
we consider unnecessary and harmful for most practical purposes. A lot of effort
is spent to restrict
[functional](https://iohk.io/research/papers/#marlowe-financial-contracts-on-blockchain)
or
[imperative](https://solidity.readthedocs.io/en/v0.5.11/solidity-by-example.html)
languages to allow feasible smart contract abstractions, yet we think much
simpler but almost equally expressive means have barely been explored so far in
a smart contract setting. Arguably a lot of the current effort is trying to
reduce most of these more expressive semantics to something that looks a lot
like Datalog, but is still harder to reason about than a simple language like
Datalog. [^2]

[^2]: What if you could use SQL to check transactions into the same SQL
    database? You should be able to build a similar library to `invariant` then. But
    do you really not want to use a logic language with variables that allow a
    compact implicit joins instead of throwing in another bunch of where clauses to
    join over multiple "tables"? Datalog is so much more concise and easy to extend
    by user-defined rules...


## Desiderata 

Let's define a minimal set of requirements that each `invariant` query needs to
satisfy:

1. Our query results must be deterministic and verifiable by other peers later.
2. Each query must terminate. This means it cannot be [Turing
   complete](https://en.wikipedia.org/wiki/Turing_completeness). Most smart
   contract language achieve this through a resource model, e.g. by requiring
   gas to run. Datalog on the other hand allows to determine ahead of time how
   many resources will be needed for a query.
3. The query might not interact with anything but the database.
4. We need to restrict write operations to a sandbox so that all invariants for
   attributes changed by the transaction are maintained.
5. The language for invariants must have meaningful and efficient access to the
   database.
6. Access to the system must be operable in a permissionless setting, i.e.
   potentially anybody can register, deploy invariants and add transactions for
   a fee. This can be flexibly restricted, e.g. by regulating access through
   another trusted system.
7. The schema for the database is extendable by each user for themselves through
   public-private key cryptography.

We naturally use our concise query language Datalog to verify transaction data.
The Datalog flavor implemented by datahike is a natural fit for the first 5
points, in particular its combination with hitchhiker trees. We address the
details of 6 in the following and 7 will be added for our test-net
implementation.

## Invariant

What exactly is an an invariant? Invariants in general describe things that stay
the same. While we think that fairly simple invariants are the most important
building blocks in describing interesting systems, e.g. for accounting, our
system can also express invariants that describe complicated dynamics, e.g. that
a value must be counted up on each change. This is possible because the
invariant queries can reason about the change itself. 

But can we really express all the smart contract examples out there in Datalog?
Our team has years of commercial and scientific experience with Datalog and we
believe that writing reliable code with Datalog is conceptually much more secure
and better understandable than in other smart contract environments. Datalog is
used in [large scale program verification](https://semmle.com/) for good
reasons. We also want to note that almost all interesting laws can be expressed
as invariants, e.g. energy conservation in physics. In case some primitives will
be missing it is as easy to add additional primitives as adding a pure Clojure
function to the datopia runtime and whitelisting it. Extensions with safe forms
of λ-calculus similar to [datafun](https://github.com/rntz/datafun) are possible
as well.

# Warmup example


- TODO sketch by drawing figures, then describe

- have simple self-explaining Datalog example

- i like the idea of establishing some trivial graph theoretic property that
  could be discussed in the context of a social network or dbpedia-style
  ontology, because these are easy to visualize

- e.g. detecting cycles in category hierarchies, or even something more trivial
  like enforcing account-blocking rules for a social network - maybe that's too
  trivial, but you get the idea.
  
 
- explain 4 types of databases passed


 
# Accounting example

Let's move on to the more practical example of accounting.
[Accounting](https://en.wikipedia.org/wiki/Accounting) is a fundamental form of
bookkeeping that has been around since humans have tracked their possessions.
For simplicity we will model an asset we call `datacoin`. To deploy our contract
we use our public key prefix `0x64703/datacoin`.

We do not need to describe how to do an asset transfer, we only need to describe
what properties need to be fulfilled for it to be valid. The submitter of the
transaction data can use any program to generate the transaction data that will
be submitted later. Assuming asset transfer transactions have authenticated
senders, e.g. by public-private key cryptography that is provided by the system,
we need at least the following three invariants to have a contract in place that
I would risk putting money in:

1. Zero-Sum
2. Positivity of Accounts
3. Sender is spending

Zero-Sum means that after each transaction the total sum of assets in the system
should not change. Positivity of accounts means that you cannot overdraft your
account into a negative balance. Finally only a signing sender can spend money
in a transaction.

The full invariant for `0x64703/datacoin` then looks like:

~~~clojure
[:find ?matches .
 :in $before $after $empty+txs $txs
 :where
 ;; run the sub-query
 [(subquery [:find (sum ?balance-before) 
                   (sum ?balance-after) 
                   (sum ?balance-change)
             :with ?affected-account
             :in $before $after $empty+txs $txs
             :where
             ;; Unify data from databases and transactions with affected-account
             [$after      ?affected-account         :0x64703.account/balance    ?balance-after]
             [$empty+txs  ?affected-account         :0x64703.account/balance    ?balance-change]
             [(get-else $before ?affected-account :0x64703.account/balance 0) ?balance-before]

             ;; 2. Positivity
             [(>= ?balance-after 0)]

             ;; 3. Sender spending
             [$txs _ _ :transaction/signed-by ?sender]
             [(= ?sender ?affected-account) ?is-sender]
             [(>= ?balance-change 0) ?pos-change]
             [(or ?is-sender ?pos-change)]]
            $before $after $empty+txs $txs)
  [[?sum-before ?sum-after ?sum-change]]]
 ;; 1. Zero-Sum aggregated
 [(= ?sum-before ?sum-after)]
 [(= ?sum-change sum-change-expected) ?matches]]
~~~

Let's break it down. First we note that we support a `subquery` functionality by
our invariant library for both Datomic and datahike. The subquery here unifies
the database against each `?affected-account`. It first binds the respective
balances from the supplied databases. This is effectively an extension of
Datalog with aggregation. Additionally it provides a form of lambda abstraction
that can be reused and adjusted to custom arguments and return types.

Note that these attributes are easy to describe on a systematic level, but we
have for instance never defined between how many participants these transactions
happen and how they should be supplied to the system or which other transactions
they are transacted with. By splitting up the constraints by attribute we can
achieve compositionality between constraints of different attributes, because
they can also reason about each other.

Finally the 4 different representations, $before, $after, $empty+txs and $txs,
allow to optimize the calculation of each invariant by different representations
of the change applied to the database. $before and $after work well for
selective queries, but might be prohibitively expensive to aggregate. For this
reason $empty+txs allows to reason about an empty database populated only with
this transaction data and finally about the list of transactions themselves. We
think this setup is sufficient to express many common invariants conveniently
and efficiently.

<!---
## Extension

It is equally easy to do double accounting in the same system by booking things
under respective debit and credit attributes. That way a similar zero-sum
predicate can be used to ensure that all accounts stay consistent. This is left
as an exercise to the reader :).

-->

# Design aspects 

## Cost model for datopia

Reading from datopia will not cost anything as the database is replicated over a
peer to peer network freely. Writing to the database costs the execution of
invariant queries for each modified attribute though. We have not defined a full
cost model for aggregation yet, but we know already that generally index
accesses will cost most gas. This is in contrast to low-level gas models like
Ethereum, because we optimize for resources that are used after compiling a very
efficient executable of the contract in form of a query plan. The CPU time that
is required to operate the query engine is negligible compared to the cost to
access the underlying storage. By decoupling of the resource cost model we can
improve the runtime. Suppliers of transactions will automatically reap the
benefits without any changes to the deployed invariants. We assume that that way
many invariants stay attractive for long periods of time. This is in contrast to
Ethereum, which specifies a cost model on instruction level, which means that
the overlaying code needs to be recompiled to use less resources when new
optimizations are added to the library or compiler.

## Deployment of invariants

How do we deploy invariants into the system then in the first place? We need to
make sure that the deployed code does not harm the system when it is executed
and that the code artifact does not affect the queries of other users. To make
sure that the deployed code does not harm the system we parse it and check that
it only uses our supported set of Datalog clauses and aggregates. Since these
are not able to affect the environment and are guaranteed to halt every provider
of the system should feel fine to accept them if a (profitable) fee is provided.
We will even add a good, established Datalog query planning framework to ensure
that each query will complete by upperbounding the costs of the query plan
upfront. This is incredibly hard to do for Turing-complete programming
languages, even if they have a strong type system.

Since adding an invariant is just another form of transaction and its addition
happens under the namespace of a public-key id of the sender, we need not
constrain users from supplying invariants. We can just ask to pay a moderate fee
for the IO operations that it costs to add one or a bunch of such contracts. 


## Optimal interface


While in most blockchain systems users need to fetch all data transacted to read
arbitrarily from the blockchain, in datopia it is enough to follow the Merkle
proof to the leafs of each index tree. [^3] We are confident that with most
meaningful contracts and apps, the partition in index fragments will be almost
information theoretically optimal for clients, because the query plan will be
minimized by detailed statistics of the distribution of each attribute and these
should cluster as well as they do for conventional applications. In other words
each client will only download the data it needs from the giant database (plus
an approximately constant size overhead). Additionally we will gain the same
expressivity as for the original query language with the benefit from all
optimizations to the query planner.

[^3]: Technically we also need a way to verify the root of the tree, we can
    conceive one way to do so by using a closed consensus system like
    Cosmos/Tendermint so clients will be able to tell easily whether a block is
    valid by following the global sequence and checking the majority validation
    of the root.


We want this interface to be widely available. In fact it is a middleware for
both datomic and datahike right now and can be combined with different
transactor implementations based on Cosmos/Tendermint, a proof-of-work based
transactor or a managed, privileged set of servers. In other words datopia can
run in any combination with a transaction mechanism. It is demonstrating one way
to expose the query language to the transactor to achieve our objectives.


# Try it out

Link to repo with datomic walk through (?)

# Conclusion

Smart contracts are solved.



# Maybe Related Work

- Bitcoin
- Ethereum
- https://github.com/juxt/juxt-accounting


- Moe Prior Art:
 - Postgres functionality (CREATE CONSTRAINT TRIGGER), for execution of arbitrary (unbounded) verification procedures per row or tx to determine fitness (in addition to first class pkey/fkey/uniqueness constraints, obv.).  Triggers are obviously widespread, w/ some creative interpretations of the standard, though the ability to validate an entire transaction pre-commit (per postgres) is closer to Datopia & more interesting than column-level constraints for the types of invariants we're interested in enforcing 
 - RDF "Query shape maps" in Shacl - A lot of this stuff is buried under RDF-specific terminology and unlikely to be of much explanatory use when talking to a general audience, though it's conceptually pretty close, and looks like a less interesting/powerful graph validation scheme - e.g. "The query shape map extends the fixed shape map to enable simple pattern matching to select focus nodes from the data graph. This is done by permitting the node selectors to be either an RDF node as in a fixed map or a triple pattern. A triple pattern can have a focus keyword to represent the nodes that will be validated and a node or wildcard (represented by the underscore character _)."  Some of the high level principles, like homoiconicity (you can validate everything, defining validation rules as triples) are cute http://book.validatingrdf.com/bookHtml010.html
- Other RDF-centric graph validation techniques using OWL dialects w/ varying
  complexity/decidability guarantees. RDF is obviously not a technology widely
  deployed in transaction processing systems, but there's some congruent
  thinking
  https://www.w3.org/TR/owl2-profiles/#Reasoning_in_OWL_2_RL_and_RDF_Graphs_using_Rules


# TODO incorporate prior discussions

## UseCases

- taken from https://github.com/datopia/planning/wiki/UseCases

- MOE: Useful data should be put on chain to allow informed execution of bureaucracy. In general on chain data should be cheap and be provided easily.

- Justin: Mineral rights are generally handled through small county clerk offices. Large oil companies need to go in and figure out who owns what. They employ a lot of folks called land men.


## Etherpad

- Moe on flesh out code examples

>>> It makes sense to me to use Datomic only in the samples, and note its applicability to Datahike, for publicity reasons.  We can focus on its generality in title / intro, but should prob. pick a backend and stick with it for the code.


- Judith: invariants in other DBs
  - some specific invariants are implemented in most schema-on-write DBs: not null, unique, foreign key, data type
  - DBs using SQL often allow more extensive invariants being formulated: column and table constraints (CHECK and CONSTRAINT clauses), e.g. Postgres, MariaDB  (give example of SQL statement?)
  - MongoDB since schemaless/schema-on-read doesn't support invariant checks


- Moe on accounting
  >>> I think accounting is much more appealing than travel expenses - happy to go with that.  Unless we can think of an interesting invariant in which the triples represent something people naturally think of in terms of graphs - that might be easier to visualize.  But nothing's really jumping out at me.  Might be interesting to think of something impressively complex along those lines for a follow-up.
  
- Moe on column only constraints
>>> We can work up to it, but the idea of transaction constraints (per the postgres point below) may be worth working up to incrementally - esp. b/c plsql stored procedures and whatever else you can evaluate in-db are potentially undecidable and unsandboxed (& perrhaps imperative/immune to advanced optimizations &c).  conceptually trivial invariants like zero sum value transfer would require tx-level constraint triggers (i.e. multi-row) to enforce atomically in a relational database. once we introduce the requirement of hard determinism, general purpose validation languages are out, and once we introduce open schemas, SQL starts looking insanely verbose.  I think a general, intuitive progression which terminates at a commonsense appeal to the necessity for deterministic, declarative, inferential transaction level constraints - before getting into any Datopia/Datalog specifics would be easy enough to follow.  


