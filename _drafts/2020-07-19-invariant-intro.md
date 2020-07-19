---
layout: post
title:  Validating Database Transactions With Datalog
author: Christian Weilbach, Moe Aboulkheir
summary: Using declarative logic to expressing and enforce complex data contracts.
tags: blockchain clojure code Datalog
date: 2020-07-19 00:00:00
---

<!---
Target audience: Technical, CTOs, programming expertise (non-functional), Datalog developers, Investors

Novelty: describe concept well enough for Datalog interests
-->

# Introduction

<!--
TODO link equational reasoning with variational principle
declarative programming instead of imperative contract procedures
-->

In Datopia --- [our open, distributed
database](https://blog.datopia.io/2018/11/03/blockchain-information-system/)
--- the fundamental network interaction is transaction submission: the
atomic assertion of one or more facts, which, if accepted, are
incorporated into a globally available database.  These transactions
may introduce attributes by providing schemas, as well as describe
arbitrary data in terms of previously deployed attributes.  To ensure
data coherence in an open network, the originator of an attribute
requires some means of representing the conditions under which it may
sensibly be used.

Given our use of [Datalog](https://en.wikipedia.org/wiki/Datalog) on
the query side, we found it natural to express data properties as
declarative queries: a transaction is applied only if we're able to
unify all invariants associated with its attributes.  While a given
invariant check is triggered by its attribute's _use_, the invariant's
query has access to the wider database, as well as the values in the
transaction itself.  In practice, this allows for the expression of
anything from simple write controls to surprisingly complex data
contracts (e.g. value exchange via direct balance manipulation,
double-entry accounting, enforcement of acyclic graphs).

Our specific solution is available as
[invariant](https://github.com/datopia/invariant): a lightweight,
independent Clojure library usable with
[Datahike](https://github.com/replikativ/datahike) and
[Datomic](https://datomic.com).  We believe it's both simple and
general enough to be of use to those developing applications atop
those databases, regardless of context --- and would appreciate
contributions and API input.  Below, we'll describe how we settled
on this approach, and detail how it's used in Datopia.

{%notpara%}

This post assumes knowledge of both Datalog and Clojure.

{%endnotpara%}

# Requirements

Invariants aren't only used in for application-level expectation
enforcement: Datopia's operation relies on the coherent, restricted
use of a set of fundamental attributes described in the _origin
schema_.  When evaluating possible approaches, we ideally wanted to
rely on a single mechanism for verifying _all_ writes, and
determined the solution ought to address the following criteria:

Inviolable
: Database-external validation (e.g. in application code) is
impractical with a diverse/open set of clients, or a large volume of
interdependent data --- and is trivial to circumvent by omission.

Contextual
: Complex invariants may have a need to incorporate inputs beyond
a single attribute write, or writes in the current transaction.

Deterministic
: Block producers are required to agree on the database contents after
 processing each block of transactions --- invariants must reproducibly
 pass/fail given the same inputs.

Quantifiable
: The complexity of an invariant must be calculable prior to
execution, and ideally at the time the invariant is deployed.

# Solution

As outlined above, `invariant` allows for Datalog queries to be
persistently associated with individual attributes --- and provides an
API which ensures the queries unify whenever the corresponding
attribute is used in a transaction.  The benefits are several: Datalog
is [Turing
incomplete](https://en.wikipedia.org/wiki/Turing_completeness),
deterministic[^1] --- and upper bounds on a query's resource
consumption are obtainable in principle via query planning.

[^1]: While pure Datalog is non-deterministic, Datahike and Datomic
    support non-deterministic aggregates (e.g. `rand`, `sample`).
    Datopia permits aggregation, but forbids user-defined functions or
    non-deterministic expressions.

To better understand where invariants fit in with Datopia's transaction
processing, let's go over the relevant steps a block producer
follows when receiving a transaction over the network.[^2]

[^2]: There'd be additional verification if the transaction were
    deploying an attribute, or introducing an invariant --- for
    simplicity, we'll cover the simple case.

1. Augment transaction with attributes synthesized from the envelope (e.g. `datopia.tx/signed-by`).
2. Interrogate database deployment for invariant queries associated
with any attribute used in the transaction.
3. Assert that all invariant queries unify.
4. Apply the transaction itself.

{%notpara%}

Further to #3, each invariant is provided the following four
relations, named by convention:

{%endnotpara%}


`$before`
: The database prior to applying the transaction.

`$after`
: The database after speculatively applying the transaction --- `(db-with db tx)`

`$empty+tx`
: An empty (i.e. schema-only) database containing only the
  speculatively applied transaction --- `(db-with (empty-db) tx)`.

`$tx`
: The transaction vector itself.

# Accounting Example

{%infobox Public Keys &amp; Namespaces%}
To prevent squatting, all attributes are created with a namespace
consisting of the deployer's public key.  Below, we're assuming the
existence of an account with public key `0x64...` --- referred to as
`0x64` for brevity (with a namespace of `x64`).
{%endinfobox%}

{%notpara%}

Our user wants to model an asset called `lcoin` (Lambdacoin), and
submits the following (idealized) transaction to the Datopia network:

{%endnotpara%}

```clojure
#:db{:ident       :x64.lcoin/balance
     :valueType   :db.type/bigdec
     :cardinality :db.cardinality/one}
```

{%notpara%}

If everything goes well, anyone can now give themselves whatever
Lamdacoin balance they want! Unfortunately, that's not exactly what
`0x64` had in mind.  Let's augment the attribute with an invariant
query which enforces the following properties:

{%endnotpara%}

Zero-Sum
: Maintain a constant global asset sum; transfers can't inflate/deflate supply.

Balance Positivity
: No overdrafts; balances bottom-out at zero.

Sender Spends
: Expenditure is restricted to the signing sender/s of the transaction.

{%notpara%}

The invariant is associated with the attribute by populating the database
with an entity having an `:invariant/rule` of `:x64.lcoin/balance` and
an `:invariant/query` attribute containing a string representation of the
query.

{%endnotpara%}

## Query

{%notpara%}

To begin with, an intermediate query yielding the aggregate difference
across all affected balances:

{%endnotpara%}

```clojure
[:find (sum ?balance-change) .
 :in   $before $after $empty+tx $tx
 :with ?entity
 :where
 ; Only consider entities affected by the transaction.
 [$empty+tx ?entity :x64.lcoin/balance _]

 [$after ?entity :x64.lcoin/balance ?balance-after]
 ; Bail-out early if the entity's balance will be negative.
 [(>= ?balance-after 0M)]

 [(get-else $before ?entity :x64.lcoin/balance 0M) ?balance-before]
 [(- ?balance-after ?balance-before) ?balance-change]

 [$empty+tx _ :datopia.tx/signed-by ?sender]
 [(= ?sender ?entity) ?is-sender]
 [(>= ?balance-change 0M) ?pos-change]
 ; If the balance is decreasing, it must belong to a signatory.
 [(or ?is-sender ?pos-change)]]
```

{%notpara%}

We'll embed this as a sub-query within our invariant, though it's
doing all of the lifting itself.  Now, let's assume database
containing the following entities (with angle-bracketed names serving
as placeholders for irrelevant values):

{%endnotpara%}

```clojure
[{:datopia/id        <sender>
  :x64.lcoin/balance 1M}
 {:datopia/id        <recipient>}]
```

{%notpara%}

We then evaluate our query against it, in the context of the following
transaction, which looks to move one Lamdacoin unit from `<sender>` to
`<recipient>`:

{%endnotpara%}

```clojure
[[:datopia.fn/call + <sender>    :x64.lcoin/balance -1M]
 [:datopia.fn/call + <recipient> :x64.lcoin/balance +1M]
 ;; As noted above, this is derived by the block producer; it's
 ;; included here for clarity
 {:datopia.tx/signed-by <sender>}]
```

{%notpara%}

Which'll yield `0`, the total difference between all affected balances
before and after the transaction is considered.  The balance writes
are expressed commutatively, in terms of the transactional utility
function `+`.

The invariant evaluator expects us to supply a query which won't unify
on failure, so we'll nest our query above within another which
requires the aggregate to total `0`:

{%endnotpara%}

```clojure
[:find ?sum-change .
 :in   $before $after $empty+tx $tx
 :where
 [(subquery
   [:find (sum ?balance-change) .
    ... ;; query as above
   ] $before $after $empty+tx $tx) ?sum-change]
 [(zero? ?sum-change)]]
```

{%notpara%}

The `subquery` form is expanded by the `invariant` library into a
backend-specific (i.e. Datahike, Datomic) query expression --- here,
we pass it the sources available to the top-level query, and bind its
result to the scalar `?sum-change`.

The result of this query --- nothing, if the subquery yields an
unacceptable value for `?sum-change`, and some truthy value otherwise
--- determines whether a transaction writing to `:x64.account/balance`
will succeed.

{%endnotpara%}

# Conclusion

Datalog --- one of the more expressive, effective languages used in
database systems today --- promises a simple solution to a large
subset of the problems addressed by procedural smart contracts.

We're still evolving the ideas around Datopia and are looking forward
to community feedback!

## Try It Out

{%notpara%}

You can find the code at
[datopia/invariant](https://github.com/datopia/invariant) on Github.

{%endnotpara%}

# Footnotes
