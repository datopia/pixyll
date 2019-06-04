---
layout: post
title:  Add your invariant to datopia
author: Christian Weilbach
summary: TODO
tags: blockchain clojure code datalog
date: 2019-06-03 12:00:00
---


# Motivation

<blockquote class="literal left">
TODO
</blockquote>

## Problem

- databases often need invariants
- invariants are typically encoded in logic languages and verified with these
  systems, e.g. type systems or formal verification (some references)
- databases already have a logic language
- but not used to encode logical constraints e.g. PostgresSQL triggers
- turing complete non-logic language, fully trusted in sandbox (might not
  terminate), ugly (show how ugly?)
- deployment of invariants often require highly privileged access to the
  database for this reason
- overall heavy to use and get right
- blockchains are all about invariants, addressing invariants for databases in
  general provides us with a good solution for datopia
 

## Warmup example


- To explain: What is an invariant? 

- TODO sketch by drawing figures, then describe

- have simple self-explaining datalog example

- i like the idea of establishing some trivial graph theoretic property that
  could be discussed in the context of a social network or dbpedia-style
  ontology, because these are easy to visualize

- e.g. detecting cycles in category hierarchies, or even something more trivial
  like enforcing account-blocking rules for a social network - maybe that's too
  trivial, but you get the idea.
  
 
 
# Requirements

- restrict write operations so that invariant is never violated, i.e. violating
  transactions are rejected
- use logic language datalog itself to verify transaction data
- deterministic
- guaranteed to terminate
- automatically sandboxed through restricted query language environment
- exploit that naturally composable with datalog database query engine
- permissionless, invariants can be deployed by users/app developers: open schema, lightweight


# Accounting example

- [accounting](https://en.wikipedia.org/wiki/Accounting) is a fundamental form of bookkeeping
- bitcoin as an invariant for attribute `:account/balance`
- asset transfer invariants
  1. Zero-Sum
  2. Positivity of Accounts
  3. Sender is spending

    
- TODO destructure
- explain subquery
- explain 4 types of databases passed
    
~~~clojure
[:find ?matches .
 :in $before $after $empty+txs $txs
 :where
 ;; run the sub-query
 [(subquery [:find (sum ?balance-before) (sum ?balance-after) (sum ?balance-change)
             :with ?affected-entity
             :in $before $after $empty+txs $txs
             :where
             ;; Unify data from databases and transactions with affected-entity
             [$after      ?affected-entity         :account/balance    ?balance-after]
             [$empty+txs  ?affected-entity         :account/balance    ?balance-change]
             [(get-else $before ?affected-entity :account/balance 0) ?balance-before]

             ;; 1. Zero-Sum
             [(+ ?balance-change ?balance-before) ?computed-balance-after]
             [(= ?balance-after ?computed-balance-after)]

             ;; 2. Positivity
             [(>= ?balance-after 0)]

             ;; 3. Sender spending
             #_[$txn    _                 :transaction/signed-by ?sender]
             #_[(datopia.attribute-invariants/balance-check
                 ?sender ?affected-entity ?balance-before ?balance-after)]]
            $before $after $empty+txs $txs)
  [[?sum-before ?sum-after ?sum-change]]]
 [(= ?sum-before ?sum-after)]
 [(= ?sum-change sum-change-expected) ?matches]]
~~~



# Cost model for datopia

- index accesses cost gas


# Extension

- double accounting with transferring between different accounts under debit/credit

# Try it out

- datomic walk through (?)

# Conclusion


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


