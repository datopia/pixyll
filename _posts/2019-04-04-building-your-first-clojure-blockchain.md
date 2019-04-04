---
layout: post
title:  Building Your First Clojure Blockchain
author: Moe Aboulkheir
summary: We'll use Clojure to build a simple, distributed key-value store atop Tendermint.
tags: blockchain clojure tendermint tutorial code
date: 2019-04-04 11:46:00
---

# Blockchain Basics

Alternatively, <a href="#impl">jump to the annotated implementation.</a>

## What?

Blockchains are networks which periodically serialize events into _blocks_,
cryptographically linking each <b>block</b> to its predecessor, forming a
<b>chain</b>.  While these events --- the entries in each block --- are often
assumed to be _transactions_ (in the financial sense) they may just as well
be
[database transactions](https://blog.datopia.io/2018/11/03/blockchain-information-system/),
[function invocations](https://ethereum.org), or anything a network might be
interested in maintaining immutable, sequential records of.

## Why?

We're mostly concerned with public/_open_ blockchains, and find them
compelling for many of the same reasons all peer-to-peer networks are --- they have
no owner.  Blockchains can
maintain
[consistency guarantees](http://hackingdistributed.com/2016/03/01/bitcoin-guarantees-strong-not-eventual-consistency/) which
permit solutions to
e.g. the [double-spend problem](https://en.wikipedia.org/wiki/Double-spending),
_without recourse to a central authority_.  Regardless of the primary purpose of
a network, the ability to selectively meter access to resources ---
using an asset represented within the network itself --- is a far-reaching
facility, when considered in full<sup>1</sup>.

<div class="footnote"> <span class="small">
<sup>1</sup> The lack of an intrinsic cost model, tamper-evidence, strong identity and granular access controls in traditional databases is responsible for innumerable special-purpose APIs which do little but conceal databases from users.  This is sometimes referred to as "backend development".
</span>
</div>

## How?

Without drifting too far into the abstractosphere, it may be useful to consider
distributed systems as
fractal
[state machines](https://en.wikipedia.org/wiki/Finite-state_machine).
[Consensus](https://en.wikipedia.org/wiki/Consensus_(computer_science))
protocols --- the rules which govern _who ought to do what, and when_ ---
describe states and the transitions between them.  The distributed applications
running atop them similarly function as deterministic state machines, transitioning
in response to consensus events and user interaction.
Some platforms --- e.g. [Ethereum](https://www.ethereum.org/) --- add another
layer, allowing the execution of user-submitted programs, themselves
often
[implemented as state machines](https://solidity.readthedocs.io/en/v0.4.24/common-patterns.html).

Open networks are also required to
be [Sybil-resilient](https://en.wikipedia.org/wiki/Sybil_attack); naive
mechanisms for apportioning influence (e.g. by vote count) are trivial to
subvert.  While this consideration is often conflated with consensus, a
network's Sybil-resilience mechanism is separable from the means by which it
attains consensus. <a name="impl">&nbsp;</a>

# Implementation

We're going to be
using
[Tendermint's](https://tendermint.com/) [Application Blockchain Interface](https://tendermint.com/docs/introduction/what-is-tendermint.html) (ABCI),
a [Go](https://golang.org) implementation
of
[Byzantine-fault tolerant](https://en.wikipedia.org/wiki/Byzantine_fault_tolerance) ---
or _classical_ --- consensus.  Tendermint's ABCI optionally supports
cross-process interaction via long-lived socket connections
and [protobuf](https://developers.google.com/protocol-buffers/)-encoded messages
--- the method we'll use, given that we're expressing our application logic in
Clojure.  Getting consensus right is _hard_, and we're attracted to the idea of
delegating it to a robust implementation, with clearly-defined boundaries.

Incoming ABCI messages typically inform applications of state transitions within
the consensus layer, or forward user-submitted transactions --- with distinct
connections used for different categories of message.  Fortunately, we'll be using
a library which spares our application from many of these details.

<div class="infobox">
<div class="infobox-title">Can I Get a Witness?</div>
<p>Tendermint is a system in which <i>witnesses</i> (or <i>block producers</i>,
<i>notaries</i>, etc). &mdash; choose your own terminology &mdash; are responsible for minting
blocks &mdash; there are at least two classes of network participants &mdash;
block producers, and everyone else.  The method by which a participant
becomes a witness, the relative influence of witnesses, and so on &mdash; these are all
trivial to implement atop Tendermint's ABCI, but also irrelevant to our example.
</p></div>

For those reading on small screens, annotations will typically _precede_ the
piece of code they're concerned with.  The code and annotations below can be found
in the [example/](https://github.com/datopia/abci-host/tree/master/example) directory
of the [datopia/abci-host](https://github.com/datopia/abci-host/) repository on GitHub.

## `project.clj`

### Dependencies

- [io.nervous/sputter](https://github.com/nervous-systems/sputter) is an
implementation of
the
[Ethereum Virtual Machine](https://nervous.io/clojure/crypto/2017/09/12/clojure-evm/),
though we're depending on it solely for
its
[trie](https://nervous.io/clojure/crypto/2018/04/04/clojure-evm-iii/),
which is discussed in outline below.
- [io.datopia/abci](https://github.com/datopia/abci-host/) uses
  a [Ring](https://github.com/ring-clojure/ring)-like approach, allowing simple
  functions to be exposed to Tendermint's ABCI client.

```clojure
(defproject io.datopia/abci-example "0.1.1"
  :description  "Tendermint ABCI example application."
  :url          "https://github.com/datopia/abci-example"
  :license      {:name "MIT License"
                 :url  "http://opensource.org/licenses/MIT"}
  :scm          {:name "git"
                 :url  "https://github.com/datopia/abci-example"}
  :aot          [abci.example.kv]
  :dependencies [[org.clojure/clojure "1.10.0"]
                 [io.datopia/abci     "0.1.1"]
                 [io.nervous/sputter  "0.1.0"]]
  :aliases      {"kv" ["with-profile" "+kv" "run" "-m" "abci.example.kv"]})
```

## `abci.example.kv`

An example ABCI application, offering comparable functionality to
Tendermint's
[kvstore.go](https://github.com/tendermint/tendermint/blob/master/abci/example/kvstore/kvstore.go) app.

`abci.example.kv` deterministically persists arbitrary EDN data structures under
keyword keys --- transactions are hex-encoded EDN literals containing one or
more keys for insertion.  There is no notion of ownership, or user identity
within the network --- we're mostly trying to hammer down the ABCI interaction
details, and hint at how a more complex system might be architected.

Application state is maintained in
a [Merkle tree](https://en.wikipedia.org/wiki/Merkle_tree) -- specifically, an
implementation
of
[Ethereum's Compact Merkle Trie](https://nervous.io/clojure/crypto/2018/04/04/clojure-evm-iii/) from
[io.nervous/sputter](https://github.com/nervous-systems/sputter), a Clojure
implementation of the Ethereum Virtual Machine, per above.

This example application has nothing to do with Ethereum --- we had to use
_some_ authenticated key/value store, and there aren't many to choose from.


```clojure
(ns abci.example.kv
  (:require [abci.host                :as host]
            [abci.host.middleware     :as mw]
            [sputter.state.trie       :as trie]
            [sputter.state.kv         :as kv]
            [sputter.state.kv.leveldb :as leveldb]
            [sputter.util
             :refer [bytes->hex]]
            [abci.example.impl.util   :as util])
  (:gen-class))
```

Our state trie requires a backing store conforming to
Sputter's
[kv/KeyValueStore](https://github.com/nervous-systems/sputter/blob/5a4917ae9f3b32b2f36512a85d03732bc054ebdf/src/sputter/state/kv.clj#L3) protocol
--- we're going with [LevelDB](https://github.com/google/leveldb), as we'd like
the trie state to persist across restarts.  We embed the port number in
LevelDB's filesystem path, allowing multiple instances of the application to
run concurrently, without stepping on each other's toes.

```clojure
(let [port    (or (System/getenv "ABCI_PORT") host/default-port)
      db-path (str "abci.example.kv-" port)]
  (defonce ^:private store
    (do
      (binding [*out* *err*]
        (println "Using LevelDB Store at" db-path))
      (leveldb/map->LevelDBStore {:path db-path}))))

(defn- map->KVTrie
  "Utility for constructing tries backed by `store`, merging
  configuration with `opts`, if provided."
  [& [opts]]
  (trie/map->KVTrie (merge {:store store} opts)))
```

After initialization, this atom holds
a
[sputter.state.trie/Trie](https://github.com/nervous-systems/sputter/blob/5a4917ae9f3b32b2f36512a85d03732bc054ebdf/src/sputter/state/trie.clj#L13) -
an implementation
of
[Ethereum's compact Merkle trie](https://nervous.io/clojure/crypto/2018/04/04/clojure-evm-iii/).
We're using it as an immutable, disk persistent, authenticated key-value store.
While we could pursue a variety of other approaches to managing state --- having
our handler function take the trie as a second parameter, and return a vector of
`[response new-trie]`, etc. --- an [atom](https://clojure.org/reference/atoms)
results in clearer and more succinct code, at least for this self-contained
example.

The trie implementation supports only `String`/bytes for keys/values, while our
application supports keyword keys, and arbitrary EDN values.  To bridge this
gap, we'll stringify all incoming keys, and print values to EDN strings.  For
example, the mapping `:a/b` -> `{:c 1}`, would be translated into `"a/b"` ->
`(pr-str {:c 1})` prior to insertion.

```clojure
(defonce ^:private trie (atom (map->KVTrie))
```
 - Values are incorporated via `trie/insert` --- an in-memory operation, returning a new trie.
 - `trie/commit` flushes pending inserts to disk, returning a trie holding
a `:hash` key --- a recursive cryptographic hash of the trie's contents / the identity of its root node.

```clojure
(comment
  (swap! trie trie/insert "key" "value"))
```

When constructing a trie, we may provide a `:root` key: a hash identifying a
node in the underlying store.  As nodes aren't ever purged, we can
_time-travel_, by specifying a stale root hash, resulting in a consistent
snapshot of the application's state at that point/block.

```clojure
(comment
  (map->KVTrie {:root (<bytes> "DAEA9...")}))
```
The key we'll use to store the most recent block height in our state trie.
We'll follow the same convention as for user submitted keys --- the
corresponding value will be the output of passing the numeric block height to
`pr-str`.

```clojure
(def ^:private height-k "abci.example.kv/height")
```

We'll persist the most recent root hash _directly_ in `store`, rather than `trie`
--- otherwise we'd have a chicken/egg problem when reconstructing a trie from the
most recently committed root hash.  As `store` follows a lower-level protocol, all of its keys are byte arrays.  This may sound confusing, initially --- it oughtn't.  On startup:

 - Determine the current root hash by recalling `last-hash-k` from `store` (low level, bytes &#8594; bytes disk-persistence protocol).
 - If the hash is non-nil (i.e.`store` has been previously used), construct a trie around `store` by passing the root hash to `map->KVTrie`.
 - The trie lazily reconstructs itself by looking up serialized nodes by content-addressed hashes, starting with the root.

```clojure
(def ^:private last-hash-k (.getBytes "abci.example.kv/hash" "UTF-8"))
```

`io.datopia/abci` ensures messages received from Tendermint'll be parsed
by [io.datopia/stickler](https://github.com/datopia/stickler), a general purpose
protobuf3 library.  ABCI messages are represented as maps, holding a
`:stickler/msg` key, identifying the underlying protobuf message type. Rather
than use an unwieldy `case` statement --- or similar --- to distinguish between
incoming message types, we'll trade some efficiency for readability, and define
a [multimethod](https://clojure.org/reference/multimethods) dispatching on each
request's `:stickler/msg` key.

We can think of `respond` as our Ring handler --- it receives requests from a
Tendermint process, and returns responses which'll be relayed to it.

```clojure
(defmulti ^:private respond :stickler/msg)
```

`wrap-default` --- applied later on --- is response middleware which expands the
literal keyword `:abci.host.middleware/default` into a generic "success" response map
appropriate to the incoming request.  Given that we may not want to special-case
_every_ possible message type, we'll use that keyword as our `respond`
multimethod's default value.

```clojure
(defmethod respond :default [_] ::mw/default)
```

`RequestInfo` is
integral to the ABCI handshake --- it's the first message we'll receive on
startup, when resuming validation of an existing chain.  The ABCI client wants
to determine our last known block height (and the corresponding state hash) so
it knows which blocks to replay, if any.  If we return the default response, all
blocks'll be replayed.

When initializing a new chain, we'll get an `InitChain` message.  Our
application has nothing to add to default response, so we don't bother
special-casing that message in our `respond` multimethod.

```clojure
(defmethod respond :abci/RequestInfo [_]
  (if-let [hash (kv/retrieve store last-hash-k)]
    (let [trie' (reset! trie (map->KVTrie {:root hash}))]
      (binding [*out* *err*]
        (println "Resuming from root hash" (bytes->hex hash)))
      {:stickler/msg        :abci/ResponseInfo
       :last-block-app-hash hash
       :last-block-height   (util/edn-value trie' height-k)})
    ::mw/default))
```

When beginning a new block, insert (in memory) the block height into the state trie (in
memory), returning a default success response.

```clojure
(defmethod respond :abci/RequestBeginBlock [{header :header}]
  (let [height-v (pr-str (:height header))]
    (swap! trie trie/insert height-k height-v))
  ::mw/default)
```
On receipt of a `RequestCheckTx` message (transaction validation), use
`util/valid-tx?` to determine the `:code` value for the outgoing response map.
The `wrap-code-keywords` middleware we'll apply later on expands
`:abci.code/...` keywords into the appropriate numeric constants.

```clojure
(defmethod respond :abci/RequestCheckTx [{tx :tx}]
  {:stickler/msg :abci/ResponseCheckTx
   :code          (if (util/valid-tx? tx)
                    :abci.code/ok
                    :abci.code/error)})
```

 `RequestDeliverTx` receives the user-submitted transaction as bytes in its
 `:tx` key. In our application, this is assumed to be a representation of an EDN
 map, containing key-value pairs we'll insert into `trie`.  Note that we don't
 yet call `trie/commit` to flush the changes to disk --- all
 operations are tentative until the block is committed.

```clojure
(defn- tx-map->inserts
  "Apply util/key->str to `m`'s keys, and `pr-str` to its values."
  [m]
  (into {}
    (for [[k v] m]
      [(util/key->str k) (pr-str v)])))

(defmethod respond :abci/RequestDeliverTx [{tx :tx}]
  (let [inserts (tx-map->inserts (util/bytes->edn tx))]
    (swap! trie #(reduce-kv trie/insert % inserts)))
  ::mw/default)
```

Commit a block, flushing trie writes (the block height increase, and any
user-initiated inserts) to disk.

```clojure
(defmethod respond :abci/RequestCommit [_]
  (let [{hash :hash :as trie} (swap! trie trie/commit)]
    (kv/insert store last-hash-k hash)
    {:stickler/msg :abci/ResponseCommit
     :data          hash}))
```

`RequestQuery`'s `:data` key ought to hold a byte array representation of a keyword,
which we'll lookup in a clean trie constructed around the hash
 of the last committed block.  While the ABCI API allows queries at any
 height, the official `kvstore.go` example foregoes this --- as will we.
 In another concession to brevity, we'll not include Merkle proofs in our
 responses --- they're irrelevant to application structure.

`trie/search` returns `nil` if the key is non-existent; the user'll be unable to
 distinguish between absent keys and explicit `nil` values --- but we don't
 really care.

```clojure
(defn- query [in-k]
  (let [k (util/bytes->edn in-k)]
    (when (and (keyword? k) (not= k ::util/invalid))
      (when-let [hash (kv/retrieve store last-hash-k)]
        (let [committed (map->KVTrie {:root hash})]
          {::value (trie/search committed (util/key->str k))})))))

(defmethod respond :abci/RequestQuery [{in-k :data :as m}]
  (if-let [m (query in-k)]
    {:stickler/msg :abci/ResponseQuery
     :code         :abci.code/ok
     :key          in-k
     :value        (::value m)}
    {:stickler/msg :abci/ResponseQuery
     :code         :abci.code/error}))
```

And, finally, some code for exposing our handler function.  `io.datopia/abci` is
fundamentally asynchronous, and uses [Aleph](http://aleph.io) for network I/O.
For cases where we'd prefer to use blocking I/O in our application,
`wrap-synchronous` invokes `handler` from a pooled worker thread, returning a
deferred representation of its result.

```clojure
(defn- wrap-handler
  "Wrap `handler` with application-appropriate middleware.
   Return a new handler fn."
  [handler]
  (-> handler
      mw/wrap-synchronous
      mw/wrap-default
      mw/wrap-envelope
      mw/wrap-code-keywords))

(defn -main [& args]
  (let [port (some-> (System/getenv "ABCI_PORT") Integer/parseInt)]
    (host/start (wrap-handler respond) (when port {:port port}))))
```

## `abci.example.impl.util`

Most of the functions in this namespace are trivial, and don't warrant
reproduction --- perhaps excepting `valid-tx?`.  `bytes->edn` returns
`::invalid` if the transaction bytes aren't valid EDN.

```clojure
(defn valid-tx?
  "Do the bytes in `tx` represent a valid transaction?"
  [tx]
  (let [tx (bytes->edn tx)]
    (and (map?      tx)
         (not-empty tx)
         (every?    keyword? (keys tx)))))
```

# Running

When developing, it's often most convenient to run a single `tendermint` process,
connected to an `io.datopia/abci` application running in a REPL.  To end the
post, we'll set up a virtual network to get a better sense of what happens when
an application comes to life.

## Validator Setup

We'll first generate the node metadata for a 3 validator cluster on a single
machine with the `tendermint` binary's `testnet` subcommand.  We'll be
using [docker-compose](https://docs.docker.com/compose/) to instantiate a
network with minimal effort, and may as well use Docker for setup:

### `bin/setup`

```sh
#!/usr/bin/env bash
# -*- mode: sh -*-

docker run -it --rm                            \
       -u root                                 \
       -v "/tmp/testnet:/tendermint/mytestnet" \
       tendermint/tendermint:0.26.0            \
       testnet                                 \
       --v 3                                   \
       --populate-persistent-peers             \
       --starting-ip-address 192.167.10.2
```

The now-current `io.datopia/abci` artifact targets Tendermint `0.26.0`, hence
the Docker image tag above.  On completion, we'll have 3 validator metadata
directories (`node0`, `node1`, `node2`) below the host's `/tmp/testnet`
directory (per the `docker` volume mapping) above:

### `docker-compose.yml`

The contortions in the `command` section enable the `docker.host.internal`
hostname to address the container's host on Linux, in a similar way to the
out-of-the-box support on OS X.

```yml
version: '2'

services:
  kv0:
    image:      tendermint/tendermint:0.26.0
    ports:      ['26670-26671:26656-26657']
    user:       root
    restart:    on-failure
    entrypoint: /bin/sh -c
    volumes:
      - '/tmp/testnet/node0:/tendermint'
    command: >
      "ip -4 route list match 0/0 |
       awk '{print $$3\" host.docker.internal\"}' >> /etc/hosts &&
       tendermint node --proxy_app=tcp://host.docker.internal:26658"
    networks:
      localnet:
        ipv4_address: 192.167.10.2

  kv1:
    #...
    ports:      ['26672-26673:26656-26657']
    command: >
      "...
      tendermint node --proxy_app=tcp://host.docker.internal:26659"
    networks:
      localnet:
        ipv4_address: 192.167.10.3

  kv2:
  #...
  ports:      ['26674-26675:26656-26657']
  command: >
      "...
      tendermint node --proxy_app=tcp://host.docker.internal:26660"
  networks:
    localnet:
      ipv4_address: 192.167.10.4
```

## Tying the Knot

In addition to starting the Tendermint containers, we  want
 3 JVMs, each hosting `abci.example.kv`, exposed on the
3 ports we supplied to `--proxy_app`, above (26658, 26659, 26660);

```sh
example$ bin/setup
example$ docker-compose up
example$ ABCI_PORT=26658 lein kv &
example$ ABCI_PORT=26659 lein kv &
example$ ABCI_PORT=26660 lein kv &
```

Once all of the JVMs are running, we ought to see some blocks being minted in
the `docker-compose` output.  While that's entertaining enough,
there's a `bin/insert-map` shell script included with the example
project, expecting to be pointed at the HTTP API of a `tendermint` process (26657, or whatever 26657 is mapped to on the host, in the Docker case).  Referring to
`docker-compose.yml`, the API ports are 26671, 26673 and 26675, respectively.  Assuming
the network is healthy, it doesn't matter which we use:

```bash
example$ bin/insert-map --port=26671 <<< '{:a "this is a" :b "b"}'
```

We can query the current value of a given key, by manually using the HTTP API, and supplying it a hex-encoded keyword literal prefixed with '0x':

```bash
example$ curl "localhost:26671/abci_query?data=0x$(xxd -pu <<< ':a')" | \
  jq -r .result.response.value | \
  base64 -d
# ->
"this is a"
```

(On OS X, that'll be `base64 -D`, because the world is a wonderful place).

All done.  As noted, the code is on Github, beneath [datopia/abci-host](https://github.com/datopia/abci-host/tree/master/example).
