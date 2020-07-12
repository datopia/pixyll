---
layout: post
title:  Invariants as Simple Smart Contracts
author: Christian Weilbach
summary: Datalog provides simple and expressive invariants.
tags: blockchain clojure code Datalog
date: 2019-11-06 12:00:00
---

<!---
Target audience: Technical, CTOs, programming expertise (non-functional), Datalog developers, Investors

Novelty: describe concept well enough for Datalog interests
-->

# Goals
{% quote Principle of Least Action, Scholarpedia|http://www.scholarpedia.org/article/Principle_of_least_action) %}
The principle of least action is the basic
variational principle of particle and continuum systems. In Hamilton's
formulation, a true dynamical trajectory of a system between an initial and
final configuration in a specified time is found by imagining all possible
trajectories that the system could conceivably take, computing the action (a
functional of the trajectory) for each of these trajectories, and selecting one
that makes the action locally stationary (traditionally called "least"). True
trajectories are those that have least action.
{% endquote %}

<!--
TODO link equational reasoning with variational principle
declarative programming instead of imperative contract procedures
-->

We have [previously established](/2018/11/03/blockchain-information-system/) the
appeal of a [Datalog based database](https://en.wikipedia.org/wiki/Datalog) in a
blockchain setting. In summary, simplicity must be a [core design
principle](https://www.infoq.com/presentations/Simple-Made-Easy) to manage
complexity in (distributed) information systems. In the following we will lay
out how Datopia can be managed by a novel, yet very simple transaction system.
We will first give a motivation for our work and how it relates to other
technologies, then describe its implementation with a simple example and a
real-world accounting contract and finally look at design aspects like cost
models. Since our concept is useful both in Datomic and Datahike, we provide it
as a light-weight, open-source library that is used by Datopia instances.

# Motivation

<!---
Motivation from database angle

composable programming model
-->

Almost every contemporary, partially automated social process uses one or more
databases to manage its internal state. These databases often provide powerful
relational logic languages like [SQL](http://www.mysql.com) or
[Datalog](http://Datomic.com) to the user. Usually these query languages do most
of the hard work to extract information for a query, efficiently scanning the
large body of accumulated knowledge. The rest of the application is often glue
code to expose the information from the database to the surroundings in form of
user interfaces or APIs. The fact that each database is contained in a silo that
way requires endless, slow and error-prone integration between different
systems.

Datopia provides support to selectively load index segments from a swarm of
peers directly into the client-side query engine instead. Our Datalog query
engine does not distinguish between the data hosted in Datopia or locally hosted
private databases in [Datahike](https://github.com/replikativ/Datahike), in
other words an arbitrary number of databases can be joint at query time at the
reader. The system composes by Datalog semantics and the efficiency of its query
planning. [We conceptualize](https://www.youtube.com/watch?v=A2CZwOHOb6U)
Datalog as a universal language for distributed systems. Datopia will therefore
automatically provide a straightforward extended Datalog dialect to extract
information on the client without the need for any intermediary server or client
functionality. Since indices are managed by [immutable data
structures](https://blog.datopia.io/2018/11/03/hitchhiker-tree/) this reading
pattern is totally decoupled and arbitrarily read scalable.[^1]

<!--- Motivation from blockchain angle -->


[^1]: A Datahike client [replication
    prototype](https://lambdaforge.io/2019/12/08/replicate-Datahike-wherever-you-go.html)
    is working on top of the [dat project](https://dat.foundation/) using its
    publish and subscribe system, but other variants on [IPFS](https://ipfs.io/)
    or [BitTorrent](http://www.bittorrent.org/) are also possible.


# Adding facts to Datopia

But what about adding new facts to Datopia and changing the database? To supply
an interface to the user with similar ease as the query interface, we would have
to constrain it in a similar way. What if... we would use Datalog also as a
language to just attach an invariant to each relation? Since Datalog is
guaranteed to halt, compact to express against a database of structured fact
triples and in general considered powerful enough to do most application logic,
we can expose our [invariant](https://github.com/datopia/invariant) library
through the Datomic or Datahike transactor to the network and let users deploy
invariants to the database similarly to smart contract systems like Ethereum. To
be sensible we of course also need to add a public-private key based
identification system and a cost model for the submission of transaction data,
which we will sketch below.

Why is this not possible with off-the-shelf PostgresSQL, CouchDB, MongoDB,
Datomic or Datahike transactor functions? These databases provide more powerful
languages to express transaction operations because they trust the code of the
database is secured by careful manual safe-guarding of the administrator.
Besides being [somewhat
odd](https://www.postgresql.org/docs/current/sql-createfunction.html) to use
programming languages, these mechanisms are therefore all Turing-complete, which
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
Datalog.[^2]

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
   contract languages achieve this through a resource model, e.g. by requiring
   gas to run. A Datalog query planner on the other hand allows to upper bound
   ahead of time how many resources will be needed for a query.
3. The query might not interact with anything but the database.
4. We need to restrict write operations to a sandbox so that all invariants for
   attributes changed by the transaction are maintained.
5. The language for invariants must have meaningful and efficient access to the
   database.
6. Access to the system must be operable in a permissionless setting, i.e.
   potentially anybody can register, deploy invariants and add transactions for
   a fee.
7. The schema for the database is extendable by each user for themselves through
   public-private key cryptography.

We naturally use our concise query language Datalog to verify transaction data.
The Datalog flavor implemented by Datahike is a natural fit for the first 5
points, in particular its combination with hitchhiker trees. We address the
details of 6 in the following and 7 will be added for our test-net
implementation.

## Invariant

What exactly is an an invariant? Invariants in general describe attributes of
some process that stay the same. While we think that fairly simple invariants
are the most important building blocks in describing interesting systems, e.g.
for accounting, our system can also express invariants that describe complicated
dynamics, e.g. that a value must be counted up on each change. This is possible
because the invariant queries can reason about the change itself.

But can we really express all the smart contract examples out there in Datalog?
Our team has years of commercial and scientific experience with Datalog and we
believe that writing reliable code with Datalog is conceptually much more secure
and better understandable than in other smart contract environments. Datalog is
used in [large scale program verification](https://semmle.com/) for good
reasons. We also want to note that almost all interesting laws can be expressed
as invariants, e.g. energy conservation in physics. In case some primitives will
be missing, it is as easy to add additional primitives as adding a pure function
to the Datopia runtime and whitelisting it. Extensions with safe forms of
λ-calculus similar to [datafun](https://github.com/rntz/datafun) are possible as
well.

# Warmup example

We start with a simple illustrative example. Let us assume we are storing
ancestor information, e.g. about family trees. To ensure that we really store
trees and do not introduce cycles into our database, we want to make sure that
nobody is ancestor of themselves. The following Datalog `query` is counting the
number of `?a`'s that are their own ancestors, and hence the total number of
people who participate in cycles.

~~~clojure
[:find (count ?a) .
 :in $after %
 :where
 ($after ancestor ?a ?b)
 [(= ?a ?b)]]
~~~

Let us assume we attempt to introduce a cycle by adding the following three
entities as a `transaction`,

~~~clojure
[{:db/id 1
  :ancestor 2}
 {:db/id 2
  :ancestor 3}
 {:db/id 3
  :ancestor 1}]
~~~

We can describe the recursive ancestor relation in a concise Datalog `rules`
with two cases,

~~~
'[[(ancestor ?a ?b)
   [?a :ancestor ?b]]
  [(ancestor ?a ?b)
   [?a :ancestor ?t]
   (ancestor ?t ?b)]]
~~~

either an entity `?a` is a direct ancestor of another entity `?b` or this
happens recursively through some transitive dependency `?t`.

We can then use the query above to speculatively apply the transactions with
`d/with` and pass it as the database snapshot `$after` into the query engine of
either Datomic of Datahike like so

~~~clojure
(d/q query
     (:db-after (d/with @conn transaction))
     rules)
;; =>
3
~~~

and detect, as expected, that the resulting database has three elements
participating in the cycle. This alLowsg us to reject the transaction outright
without it even passing into the transactor.


# Accounting example

Let's move on to the more complex example of accounting.
[Accounting](https://en.wikipedia.org/wiki/Accounting) is a fundamental form of
bookkeeping that has been around since humans have tracked their possessions.[^3]
For simplicity we will model an asset we call `datacoin`. To deploy our
contract we use our public key prefix `0x64703/datacoin`.

[^3]: An opinionated, but interesting, perspective of different monetary devices
    to account for fairness and facilitate the co-evolution of game theoretic
    mechanisms are [accounted for by Nick
    Szabo](https://nakamotoinstitute.org/shelling-out/#evolution-cooperation-and-collectibles). [This lecture of Robert Sapolsky](https://www.youtube.com/watch?v=NNnIGh9g6fA) describes the evolutionary background in more depth.



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
our invariant library for both Datomic and Datahike. The subquery here unifies
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
and efficiently, but might adapt it depending on the usage of the invariants.

<!---
## Extension

It is equally easy to do double accounting in the same system by booking things
under respective debit and credit attributes. That way a similar zero-sum
predicate can be used to ensure that all accounts stay consistent. This is left
as an exercise to the reader :).

-->

# Design aspects

## Cost model for Datopia

Reading from Datopia will not cost anything as the database is replicated over a
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
are not able to affect the environment and are guaranteed to halt, every
provider of the system should feel fine to accept them if a (profitable)
deployment fee is provided.

Since adding an invariant is just another form of transaction and its addition
happens under the namespace of a public-key id of the sender, we need not
constrain users from supplying invariants. We can just ask to pay a consistent fee
for the IO operations that it costs to add one or a bunch of such contracts.


## Optimal interface


While in most blockchain systems users need to fetch all data transacted to read
arbitrarily from the blockchain, in Datopia it is enough to follow the Merkle
proof to the leafs of each index tree[^4]. We are confident that with most
meaningful contracts and apps, the partition in index fragments will be almost
information theoretically optimal for clients, because the query plan will be
minimized by detailed statistics of the distribution of each attribute and these
should cluster as well as they do for conventional applications. In other words
each client will only download the data it needs from the giant database (plus
an approximately constant size overhead). Additionally we will gain the same
expressivity as for the original query language with the benefit from all
optimizations to the query planner.

[^4]: Technically we also need a way to verify the root of the tree, we can
    conceive one way to do so by using a closed consensus system like
    Cosmos/Tendermint or Avalanche such that clients will be able to tell easily
    whether a block is valid by following the global sequence and checking the
    majority validation of the root.


We want this interface to be widely available. In fact it is a middleware for
both Datomic and Datahike right now and can be combined with different
transactor implementations based on Cosmos/Tendermint, a proof-of-work based
transactor or a managed, privileged set of servers. In other words Datopia can
run in any combination with a transaction mechanism. It is demonstrating one way
to expose the query language to the transactor to achieve our objectives.


# Conclusion

By deploying Datalog, one of the most expressive - yet effective - languages in
database systems today, we propose a simple solution to a large subset of the
requirements often identified in smart contract systems. We are still evolving
the ideas around Datopia and are happy about your feedback! (TODO link
communication channel)


## Try it out

You can find the code in our [invariant
repository](https://github.com/datopia/invariant).

# Footnotes
