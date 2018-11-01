---
layout: post
title: An Introduction to the Hitchhiker Tree
author: Christian Weilbach
summary: "The goal of the Hitchhiker tree is to wed three things: the query performance of a B+ tree, the write performance of an append-only log, and convenience of a functional, persistent data structure."
---

<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>

# Motivation

<blockquote class="literal left">
"I will, in fact, claim that the difference between a bad programmer and a good
 one is whether he considers his code or his data structures more important.
Bad programmers worry about the code. Good programmers worry about data
structures and their relationships."
<div class="attrib">&mdash; <a href="https://lwn.net/Articles/193245/">Linus Torvalds</a></div>
</blockquote>

[Datopia](https://datopia.io) has at its center a permissionless, immutable
database --- we maintain, persist and federate parallel indices to efficiently
service structured queries over the chain state.  Our specific approach to index
implementation has involved extending
Greenberg's
[Hitchhiker tree](https://github.com/datacrypt-project/hitchhiker-tree), and,
in [datahike](https://github.com/replikativ/datahike), providing facilities for
arranging HH trees in such a way as to support interrogation
with [Datalog](https://en.wikipedia.org/wiki/Datalog), a declarative query
language.

This post is aimed at readers unfamiliar with the Hitchhiker tree --- or
write-optimized B trees, more generally.  We'll begin by revising properties of
related data structures, while incrementally suggesting the design of the HH
tree --- a functional implementation of
a [B+ tree](https://en.wikipedia.org/wiki/B%2B_tree), employing similar
write-optimizations
to [fractal tree indices](https://en.wikipedia.org/wiki/Fractal_tree_index) or
<a
href="http://supertech.csail.mit.edu/papers/BenderFaJa15.pdf">B<sup>&#949;</sup>
trees</a>.  Before parting, we'll briefly touch on authentication and
replication.  We can't cover everything: details of how indices are represented
in the HH trees will be the topic of a follow-up post.

# From The Ground Up

## Binary Search Trees

The canonical (and simplest) _tree_ data structure suitable for storing sorted
collections is
the [binary search tree](https://en.wikipedia.org/wiki/Binary_search_tree) ---
an arrangement in which inner nodes point to at most two subtrees (left and
right).  While simple, an _unbalanced_ BST is vulnerable to structural
deformation --- if, say, entries are inserted in sorted order --- and may
degenerate into an approximation of a linked list.  Accordingly, we'll set
unbalanced trees aside, and focus only  on the [balanced, or self-balancing](https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree) subset of trees ---
those in which all leaves are approximately distant from the root.

In any balanced tree, the distance between the root and a leaf scales
logarithmically with the number of entries.  In a balanced BST having $$N$$ entries,
the cost of a lookup is  $$\log_2 N$$ comparisons, where the base of the
logarithm --- 2 --- is the tree's branching factor.  Intuitively, this makes
sense: we're halving the remaining search space whenever we select a subtree for
descent.

## B+ Trees

<blockquote class="literal left">
“You need the power of the logarithm.”<br>
<div class="attrib">&mdash; <a href="https://www.youtube.com/watch?v=P-NZei5ANaQ">Rich Hickey</a></div>
</blockquote>

If we think about balanced tree lookups as involving $$\log_B N$$ comparisons
--- where $$B$$ is the branching factor --- we might consider increasing $$B$$
to yield a more favourable base for the logarithm.  The B tree family of
structures can be understood as self-balancing generalizations of the BST,
leveraging the logarithm for practical gain.

<div class="center diag" style="width: 100%">
<img src="/images/bplus_tree_annotated.png">

<span class="small">Figure 1: B+ Tree. The pivots help to navigate the tree to find the
proper data nodes containing the actual key and value of an element.</span>
</div>

So, there's a lot going on here.  We've got a B+ tree containing the integer
keys 1-29, with a minimum branching factor --- $$B$$ --- of 3.  Each index node
has between 3 ($$B$$) and 5 ($$2B-1$$) children --- excepting the root,
which may have fewer.  Navigating via the pivot values is straightforward:
the greatest (rightmost) value in any subtree is its parent's pivot.

# Write Optimization

While B+ trees leave little to be desired for reading data, they're not
write-optimal --- an insert or deletion _also_ costs $$O(\log_B N)$$, as we're
required to walk to the respective leaf prior to operating on it<sup>1</sup>.
The Hitchhiker tree attempts to asymptotically improve upon this, by buffering
write operations in fixed-length append logs associated with each index (inner)
node --- an optimization common to fractal and B<sup>&#949;</sup> trees.

<div class="center diag" style="width: 100%">
<img src="/images/hh_tree_annotated.png">
<span class="small">
Figure 2: Hitchhiker tree with append logs in each non-leaf node of size 2
</span>
</div>

In _Figure 2_ we see such a tree, with the append logs rendered vertically
at the rightmost of each index node.  If we attempt to append a
write to a full log, the contents are flushed downwards a level. Eventually,
an element arrives at a leaf and is inserted it into the data
node. Per
[Greenberg's](https://github.com/datacrypt-project/Hitchhiker tree/blob/master/doc/Hitchhiker.adoc) summary
of the benefits of this approach:

 - Most inserts are a single append to the root's event log.
 - Although there are a linear number of events, nodes are exponentially less
likely to overflow the deeper they are in the tree.
 - All data needed for a query exists along a path of nodes between the root and
   a specific leaf node. Since the logs are constant in size, queries still only
   read $$\log N$$ nodes.

Given our ability to independently alter the log length and branching factor, we
can view this data structure either as a write-optimized B+ tree, or a
read-optimized append log.  The latter property is one we're interested in
exploiting to efficiently replicate write-intensive event-logs
in [replikativ](http://replikativ.io), an associated project.

<div class="footnote">
<span class="small">
<sup>1</sup> See <a href="https://mitpress.mit.edu/books/introduction-algorithms-third-edition">Cormen et al.</a> for details.
</span>
</div>

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

The root's append log overflows, and elements 13 and 14 move rightwards, causing
another flush per _Figure 5_ --- triggering their insertion into the data layer
of the tree, and a split of the B+ tree's index node.  Critical for the
reduction in I/O costs is the fact that the newly inserted element --- -1 ---
only migrates to the node on the left, generating a single I/O operation until
the append log is filled up.

## Query

When querying a Hitchiker tree, we have to downwardly project unincorporated
append log values --- interpolating them in memory after loading the required
data nodes. In that sense, the appended values _hitchhike_ with the query
operation to their appropriate position. This doesn't require any additional
I/O, only the CPU work of sorting a few elements in the nodes. For range
queries, we selectively project downwards only the elements that belong on the
relevant path.  See the <a href="#cost">asymptotic costs</a> appendix for more
detailed information about the complexity of these operations.

# Replication

Clojure's data structures are trivial
to [structurally hash](https://github.com/replikativ/hasch/), and arbitrary data
structures may be [authenticated](https://www.cs.umd.edu/~mwh/papers/gpads.pdf)
without difficulty.  We've exploited these facts to _merkelize_ (urgh) the
Hitchiker tree, by indirecting parent-child relationships with
recursive [SHA512](https://en.wikipedia.org/wiki/SHA-2) subtree hashes, yielding
a write-optimized Merkle B+ tree.

Consequently, index segments (addressed by hash) may be replicated peer-to-peer
(e.g. [Dat](https://github.com/datproject/dat),
[Bittorrent](https://en.wikipedia.org/wiki/BitTorrent)), and selectively
retrieved by light clients in response to local queries --- database consumers
maintain local copies of whatever subset of the indices their queries touch,
without losing the ability to authenticate the entire structure, given a trusted
root hash.

# Conclusion

I hope we've explained the Hitchhiker tree's background sufficiently to
communicate its attraction to us as a building block for distributed
databases. We believe authenticated, optimized B trees to be a far better choice
for high-performance data storage solutions (blockchains, P2P filesystems) than
direct materialization of DAGs or chains.  If these ideas interest you, or
you're motivated by the composition of clearly-delineated components
into
[surprisingly powerful systems](http://www.infoq.com/presentations/Simple-Made-Easy),
consider joining us!

<a name="cost"></a>
# Appendix: Asymptotic Costs

It's clarifying to discuss complexity in the notation of B<sup>&#949;</sup> trees.
here. While a B+ tree has a fanout of $$B$$ --- each node has at least $$B$$
children --- a $$B^{\epsilon}$$ tree has $$B^{\epsilon}$$ children
(e.g. $$\sqrt{B}$$ children for $$\epsilon = \frac{1}{2}$$). Each node has $$B$$
elements: $$B^\epsilon$$ are navigational pointers while the remainder belong to
the append log.

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
