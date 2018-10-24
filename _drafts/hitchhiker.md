---
layout: post
title: Hitchhiking in Databases
author: Christian Weilbach
summary: "The goal of the Hitchhiker tree is to wed three things: the query performance of a B+ tree, the write performance of an append-only log, and convenience of a functional, persistent datastructure."
---

<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>

# Motivation

<blockquote class="literal">
"I will, in fact, claim that the difference between a bad programmer and a good
 one is whether he considers his code or his data structures more important.
Bad programmers worry about the code. Good programmers worry about data
structures and their relationships."
<div class="attrib">&mdash; <a href="https://lwn.net/Articles/193245/">Linus Torvalds</a></div>
</blockquote>

Following the logic of Linus' insight --- and applying it to our own use case ---
we might inquire after the optimal data structure to place at the center of a
distributed system servicing queries over large amounts of structured data.

In this article we'll be discussing optimizations/elaborations to
the [B Tree](https://en.wikipedia.org/wiki/B-tree), family of structures --- the
substrate of many a database index.  At the highest level, B+ Trees (a B tree variant) are
attractive because they structurally facilitate  infrequent
retrieval of leaf data --- itself presumably stored in a higher-latency medium
than memory.

We'll begin by incrementally suggesting the design of David Greenberg's
[Hitchhiker Tree](https://github.com/datacrypt-project/hitchhiker tree),
a functional data structure augmenting [B+ trees](https://en.wikipedia.org/wiki/B%2B_tree)
with novel, theoretically optimal performance trade-offs.  We'll conclude
by describing our own work in combining Hitchhiker Trees (HH trees) in such a way
as to constitute the storage backend for Datopia's inferential database.

# From The Ground Up

Let's briefly revise the properties of simpler, related tree structures, before
guiding the reader through the design of the Hitchiker tree.

## Binary Trees

The canonical (and simplest) _tree_ datastructure suitable for storing sorted
collections is the
 [binary tree](https://en.wikipedia.org/wiki/Binary_tree).  It's not
all good news --- unbalanced binary trees are subject to arbitrary structural
deformation, and in pathological cases degenerate
into [linked lists]((https://en.wikipedia.org/wiki/Linked_list)).  Setting
unbalanced trees aside, we'll consider only the subset of trees which
are
[balanced, or self-balancing](https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree) ---
a property requiring all leaves be approximately distant from the root.

## Balanced Trees

<blockquote class="literal left">
“You need the power of the logarithm.”<br>
<div class="attrib">&mdash; <a href="https://www.youtube.com/watch?v=P-NZei5ANaQ">Rich Hickey</a></div>
</blockquote>

In a balanced tree, the distance between the root and a leaf scales
logarithmically with the number of entries.  Considering balanced binary trees,
we're looking at $$N$$ --- $$O(\log_2 N)$$, i.e.  $$\log_2 N$$ operations in the
worst case to lookup a leaf node. For 1,000 entries, $$\log_2 1000 \approx
9.97$$.  Assuming a uniform distribution of entries in the key space, we can't
improve upon logarithmic lookup complexity.

### B+ Trees

While the depth of balanced trees scales logarithmically, increasing
the branching factor yields a more favourable constant $$B$$. Let's say on
each node we branch 100 times, rather than 2 --- for our 1,000
entries: $$\log_{100} 1000 \approx 1.5$$. While practically consequential,
this constant factor doesn't affect the complexity of the operation.

<div class="center diag" style="width: 100%">
<img src="/images/bplus_tree_annotated.png">

<span class="small">Figure 1: B+ Tree. The pivots help to navigate the tree to find the
proper data nodes containing the actual key and value of an element.</span>
</div>

In _Figure 1_ we see a B+ tree having a minimum branching factor of 3. The blue
data nodes contain the numbers 1-29, which we can imagine correspond to disk
storage locations for the associated data. Index nodes maintain pointers
(denoted by angle brackets), to navigate the tree. To retrieve an element from
the above tree, we'd need to read two index nodes and one data node.  The child
labels incorporate symbolic Merkle hashes (e.g. 3082 and 0681, if we examine the
root) --- of which more later.

While B+ trees leave little to be desired for reading data, they are not
write-optimal --- an insert or deletion _also_ costs $$O(\log_B N)$$, as we're
required to walk to the respective leaf prior to insertion<sup>1</sup>.

<div class="footnote">
<span class="small">
<sup>1</sup> See <a href="https://mitpress.mit.edu/books/introduction-algorithms-third-edition">Cormen et al.</a> for details.
</span>
</div>

# Fractal Combination

<div class="infobox">
<div class="infobox-title">What's a Fractal Tree?</div>
<p>
Fractal trees, in this context, can be seen as optimized B+ trees which
asymptotically reduce the cost of insertions and deletions, without affecting
the complexity of searches &mdash; via the use of <i>append logs</i> (linked
lists) to defer unnecessary I/O operations.
</p>
<p>
Given our ability to independently alter the log length and branching factor,
fractal trees may be seen either as write-optimized B+ trees, or read-optimized
append logs.  The latter property is one we're interested in exploiting to
efficiently replicate write-intensive event-logs in <a
href="http://replikativ.io">replikativ</a>.
</p>
</div>

<div class="center diag" style="width: 100%">
<img src="/images/hh_tree_annotated.png">
<span class="small">
Figure 2: Fractal Tree with append logs in each non-leaf node of size 2
</span>
</div>

In _Figure 2_ we see a fractal combination of a B+ tree, with a fixed-length
append log associated with each inner (index) node.  If we attempt to append a
write to a full log, we flush it downwards a level to the next tier. Eventually,
an element arrives at a leaf node and is inserted it into the data
node. Per
[Greenberg's](https://github.com/datacrypt-project/Hitchhiker tree/blob/master/doc/Hitchhiker.adoc) summary
of the benefits of this approach:

 - Most inserts are a single append to the root's event log.
 - Although there are a linear number of events, nodes are exponentially less
likely to overflow the deeper they are in the tree.
 - All data needed for a query exists along a path of nodes between the root and
   a specific leaf node. Since the logs are constant in size, queries still only
   read $$\log N$$ nodes.


The fractal nature of the tree is not some internal property --- both append log
size and tree branching may be picked freely on tree creation.

## Insertion

<div class="center diag" style="width: 100%">
<img src="/images/hh_insert1.png">
<br/>
<span class="small">Figure 3: A small Hitchhiker Tree</span>
</div>

In _Figure 3_ you can see a small HH
tree, containing the data nodes 0-12. Note how a few of the elements remain in
the append logs (0, 11, 12, 13) --- let's walk through the insertion of further
elements to develop our intuitions around  how the append logs are flushed down
the tree.

<div class="center diag" style="width: 100%">
<img src="/images/hh_insert2.png">
<br/>
<span class="small">Figure 4: Elements propagate first to fill up append logs of hitchhiking-elements that wait for an event to propagate them down the tree.</span>
</div>

First we insert 14, observing that it requires a single write operation on the
root node's log per _Figure 4_ --- leaving the root's append log at capacity.
Let's tempt fate and attempt to insert another element, -1:

<div class="center diag" style="width: 100%">
<img src="/images/hh_insert3.png">
<br/>
<span class="small">Figure 5: An insert causes an overflow and flushes the elements down to the leaf nodes.</span> </div>

The root's append log overflows, and the elements 13 and 14 move rightwards, causing
another flush per _Figure 5_. This triggers their insertion
into the data node of the B+ tree on the lowest level. Note how this operation
on the B+ tree also causes the B+ tree index node split. Critical for the
reduction in I/O costs is the fact that the newly inserted element -1 only
migrates to the node on the left, generating a single I/O operation until the
append log is filled up.

## Query

But what about queries? If we  consider the B+ tree part of the Hitchhiker
tree we will definitely miss the elements still waiting in the append logs. We
therefore project them down the tree during our query operation and insert them
in memory after we have loaded the data nodes. In that sense they _hitchhike_ with
the query operator to their appropriate position. This does not require any
additional I/O operation, only additional CPU work of sorting a few elements in
the nodes. For range queries we further ensure that we only project the elements
down that belong on a particular path.

## Asymptotic Costs

Since the Hitchhiker tree is fractal, we'll use the same notation
here. When a normal B+ tree has a fanout of $$B$$ --- each node has at
least $$B$$ children --- a fractal $$B^{\epsilon}$$ tree has $$B^{\epsilon}$$
children (e.g. $$\sqrt{B}$$ children for $$\epsilon = \frac{1}{2}$$). You
can think of this as the fraction of the tree that belongs to the B+ tree:eEach
node has $$B$$ elements, though $$B^\epsilon$$ are navigational pointers
while the remainder belongs to the append log.

To calculate the amortized insertion cost informally, we can say that we have to
flush an element $$\log_B N$$ times to the leaf. On each flush we move
$$(B-B^\epsilon)/B^\epsilon \approx B^{1-\epsilon}$$ elements down to each
children. For a detailed explanation see Section
2.2. of
[Jannen et al.](https://www.usenix.org/system/files/conference/fast15/fast15-paper-jannen_william.pdf)


| Cost (IO ops) | B+ tree               | HH tree                                          |
| ------------- | ---------------       | ---------------                                  |
| insert/delete | $$O(\log_B N)$$       | $$O(\frac{1}{\epsilon B^{1-\epsilon}}\log_B N)$$ |
| query         | $$O(\log_B N)$$       | $$O(\frac{1}{\epsilon} \log_B N)$$               |
| range         | $$O(\log_B N + k/B)$$ | $$O(\frac{1}{\epsilon}\log_B N + k/B)$$          |

<span class="small">Table 1: Comparison of the asymptotic complexity of operations between a
B+ tree and a HH tree.</span>


Note that while the query cost increases slightly by $$\frac{1}{\epsilon}$$, we
can target larger node sizes, as they're not rewritten as often as is the case
for a B+ tree. If we consider $$\epsilon$$ as a fixed constant (e.g.
$$\frac{1}{2}$$), it's eliminated from the asymptotic cost expressions and
yields the theoretic superiority of a fractal tree.

# Persistence

So far we have basically described the fractal tree concept, but we have already
denoted a Merkle hash on each of the edges of the trees drawn. All hitchhiker
trees are [merkelized](https://en.wikipedia.org/wiki/Merkle_tree) data
structures. This means we do not overwrite the trees in place, but in fact
implement a so called persistent data structure that returns copies after
insertion events and shares structure as can be seen in _Figure 6_. The
programming language of our choice, [Clojure](http://clojure.org), puts this
decision at the center of its design and therefore makes the Hitchhiker tree
implementation both straightforward and very robust to concurrent access.

<div class="center diag" style="width: 100%">
<img src="/images/persistence_annotated.png">
<br/>
<span class="small">Figure 6: A tree with elements 1 until 11 and a new tree after the addition of elements 12,13. </span> </div>

## Merkelized Replication

Clojure's data structures can be merklized fairly easily
with [hasch](https://github.com/replikativ/hasch/). We have exploited this fact
and changed the original Hitchhiker tree implementation to use
cryptographic [SHA512](https://de.wikipedia.org/wiki/SHA-2) pointers to children
of nodes.  Replicating an immutable data structure that way is fairly easy and
our experience with [replikativ](http://replikativ.io) has allowed us to make
the Hitchhiker tree readily available in our stack. Importantly, replication is
 bounded by the same logarithmic properties of the tree --- i.e. no element
takes more than $$O(\log_B N)$$ steps to replicate and, in aggregate,
synchronization behaves more like range queries. This is unachievable by most
blockchain systems today.

## Authentication

Since the whole data structure is properly merklized authentication is trivial.
We can in fact sign the root of the database indices for our blockchain after
each created block and replicate the index partially or in whole in a P2P
fashion with readily available read-scalable replication techniques. This will
allow light-client query flexibility and speed that goes far beyond the status
quo. We will describe this in more detail in a future post.


# Conclusion

I hope we've explained the Hitchhiker tree's background sufficiently to
communicate its attraction to us as a building block for distributed
databases. We believe authenticated HH to be a far better choice for
high-performance data storage solutions (blockchains, P2P filesystems) than
direct materialization of DAGs or chains. To facilitate structured retrieval,
we've incorporated a sound and declarative query language ---
a [Datalog engine](https://github.com/tonsky/datascript/)<sup>1</sup> --- to
leverage the strengths of the underlying structure.

If these ideas interest you, or you're motivated by the composition of
clearly-delineated components
into
[surprisingly powerful systems](http://www.infoq.com/presentations/Simple-Made-Easy),
consider joining us!

<div class="footnote">
<span class="small">
<sup>1</sup> See <a href="https://github.com/replikativ/datahike">Datahike</a> for more details.
</span>
</div>
