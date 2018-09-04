---
layout: post
title: Hitchhiking in databases
---

<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>

# Motivation

> I will, in fact, claim that the difference between a bad programmer and a good
> one is whether he considers his code or his data structures more important.
> Bad programmers worry about the code. Good programmers worry about data
> structures and their relationships.
[Linus Torvalds](https://lwn.net/Articles/193245/)

Following the popular insight reiterated by Linus we should ask: What is the
optimal building block for distributed systems that need to track considerable
amounts data? What do we need to build a distributed database like a blockchain
of? We want to store data reliably in it as efficiently and fast as possible and
more importantly we want to be able to retrieve this data whenever we need also
as efficiently and fast as possible. In this article we lay out the general
design of the
[Hitchhiker-tree](https://github.com/datacrypt-project/hitchhiker-tree), a
specially crafted functional data structure by David Greenberg:

> The goal of the Hitchhiker tree is to wed three things: the query performance of
> a B+ tree, the write performance of an append-only log, and convenience of a
> functional, persistent datastructure. Let's look at each of these in some
> detail.

[Hitchhiker-tree motivation](https://github.com/datacrypt-project/Hitchhiker-tree/blob/master/doc/Hitchhiker.adoc)

We furthermore elaborate on our work to make it distributable in the open. This
then yields the foundation for our blockchain system.


# A guide to hitchhike on trees

In this section we first build up some common notions about trees and then guide
you to the design of the Hitchhiker tree. 

The simplest tree datastructure for storing a sorted collection of entries is
the [binary tree](https://en.wikipedia.org/wiki/Binary_tree). But it is not
optimal for data retrieval because such a tree can become arbitrarily deformed.
In the worst case it just becomes a [linked
list](https://en.wikipedia.org/wiki/Linked_list). A tree is hence [defined to be
balanced](https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree) if
all leaves have approximately the same distance to the root.

Why is this a desired property? Because for balanced trees the distance from
leaf to root scales logarithmically with the number of entries $$N$$. This is
analyzed with the help of the so called [big-O
notation](https://en.wikipedia.org/wiki/Big_O_notation) and written as
$$O(\log_2 N)$$, meaning that it takes $$\log_2 N$$ operations in the worst case
to lookup a leaf node in the tree. For $$1000$$ entries it would be $$\log_2
1000 \approx 9.97$$. 

Assuming a uniform distribution of entries in the key space this logarithmic
lookup complexity is optimal. You cannot do better. Balanced trees are therefore
the go to solution to build query indices in all kinds of memory systems, e.g.
popular databases like PostgreSQL, Apache Cassandra or for your favorite file
system.

## B+ tree

While binary trees scale logarithmically already, we can use trees with a higher
branching factor to achieve a better constant factor $$B$$. Let's say on each
node we branch into $$100$$ subbranches instead of $$2$$ then we get for our
$$1000$$ entries: $$\log_{100} 1000 \approx 1.5$$. Practically speaking this
factor makes a big difference, although constant factors do not change the big-O
classification. Databases therefore use so called branching or
[B+ trees](https://en.wikipedia.org/wiki/B-tree). In fact they do one more tweak,
they only store index information in the tree and put all data to the leaf
nodes, which is a so called [B+ tree](https://en.wikipedia.org/wiki/B%2B_tree).
This ideally allows to keep all index nodes in memory and only read the data
nodes from disk as they are much bigger.

<div class="center" style="width: 100%">
<img src="/images/bplus_tree_annotated.png">
<small>Figure 1: B+-Tree</small>
</div>

In Figure 1 we can see a B+ tree with a minimum branching factor of $$3$$. The
blue data nodes contain the numbers from $$1$$ to $$29$$, while the index nodes
only have pointers, denoted in angle brackets, to navigate the tree. The tree
has a depth of three, meaning we need to read two index nodes and one data node
to retrieve each element. We have also denoted Merkle hashes on the branches and
will come back to this later.

While B+ trees leave little to be desired for reading data, they are not optimal
for writing data. An insert or deletion also costs $$O(\log_B N)$$ because we
have to walk to the respective leaf node to insert an entry there. You can look
up the details about the operations in [Cormen et
al.](https://mitpress.mit.edu/books/introduction-algorithms-third-edition) or on
Wikipedia.

## Append-log

What is the fastest way to write data? Just [append it to a
list](https://en.wikipedia.org/wiki/Linked_list) of which you know its end.
Unsurprisingly this is called an append-log (or in its simplest form a linked
list) and has write complexity $$O(1)$$. Unfortunately to retrieve data you have
to walk along the linked list, so an append-log is not optimal to retrieve data
and takes $$O(N)$$ steps to retrieve an element. Note that you can immediately
see from the big-O notation that this is significantly worse than the B+ tree.


## Fractal Combination

<div class="center" style="width: 100%">
<img src="/images/hh_tree_annotated.png">
<small>Figure 2: Fractal-Tree with append logs in each non-leaf node of size 2</small>
</div>

In Figure 2 you can see a fractal combination of a B+ tree and append logs.
[David has
described](https://github.com/datacrypt-project/Hitchhiker-tree/blob/master/doc/Hitchhiker.adoc)
this concept comprehensibly as follows:

> The first idea to understand is this: how can we combine the write performance
> of an event log with the query performance of a B+ tree? The answer is that
> we're going to "overlay" an event log on the B+ tree!
>
> The idea of the overlay is this: each index node of the B+ tree will contain an
> event log. Whenever we write data, we'll just append the operation (insert or
> delete) to the end of the root index node's event log. In order to avoid the
> pitfall of appending every operation to an ever-growing event log (which would
> leave us stuck with linear queries), we'll put a limit on the number of events
> that fit in the log. Once the log has overflowed in the root, we'll split the
> events in that log towards their eventual destination, adding those events to
> the event logs of the children of that node. Eventually, the event log will
> overflow to a leaf node, at which point we'll actually do the insertion into the
> B+ tree.
>
> This process gives us several properties:
>
> - Most inserts are a single append to the root's event log
> - Although there are a linear number of events, nodes are exponentially less
>   likely to overflow the deeper they are in the tree
> - All data needed for a query exists along a path of nodes between the root and
>   a specific leaf node. Since the logs are constant in size, queries still only
>   read `log(n)` nodes.
>
> Thus we dramatically improve the performance of insertions without hurting the
> IO cost of queries.




## Insertion

<div class="center" style="width: 100%">
<img src="/images/hh_insert1.png">
<br/>
<small>Figure 3: A small Hitchhiker-Tree</small>
</div>


Let's walk through an insertion example. In Figure 3 you can see a small
Hitchhiker-tree. With the elements $$0-12$$ inserted. Note how a few of the
elements are still in the append-logs ($$0, 11, 12, 13$$) because they have just
been inserted. We will now go through two steps inserting more elements and see
how the append-logs are flushed down to the root nodes.

<div class="center" style="width: 100%">
<img src="/images/hh_insert2.png">
<br/>
<small>Figure 4: Elements propagate first to fill up append-logs of hitchhiking-elements that wait for an event to propagate them down the tree.</small>
</div>

First we insert $$14$$ and observe that it just requires one write operation to
the root node as can be seen in Figure 4. But observe that the root node's
append-log is now full. Where will the elements go in the next step? To the
right of it in the index node. But the append-log there is also full. Let's
insert the next element $$-1$$ to the root node:


<div class="center" style="width: 100%"> 
<img src="/images/hh_insert3.png"> 
<br/>
<small>Figure 5: An insert causes an overflow and flushes the elements down to the leaf nodes.</small> </div>

The append-log will overflow and the elements $$13$$ and $$14$$ go to the right,
causing another flush there as can be seen in Figure 5. This triggers their
insertion into the data node of the B+-tree on the lowest level. Note how this
operation on the B+-tree also causes the B+-tree index node split. Critical for
the reduction in IO costs is the fact that the newly inserted element $$-1$$
does only migrate to the node on the left though, causing only one IO operation
there until the append-log is filled up.



## Query

But what about query? If we just consider the B+-tree part of the Hitchhiker
tree we will definitely miss the elements in the append-logs. We therefore
project them down the tree during our query operation and insert them in memory
after we have loaded the data nodes. In that sense they hitchhike with the query
operator to their proper position. For range queries we further ensure that we
only project the elements down that belong onto a particular path.


## Asymptotic Costs

Since the Hitchhiker tree is a fractal tree, we will use the same denotation
here. When a normal B+-tree has a fanout of $$B$$, that is each node has at
least $$B$$ children then a fractal $$B^{\epsilon}$$ tree has $$B^{\epsilon}$$
children. E.g. for $$\epsilon = \frac{1}{2}$$ that is $$\sqrt{B}$$ children. You
can think of this as the fraction of the tree that belongs to the B+-tree. Each
node has still $$B$$ elements, but $$B^\epsilon$$ are pointers for the tree
while the rest belongs to the append log.

To calculate the amortized insertion cost informally we can say that we have to
flush an element $\log_B N$ times to the leaf. But on each flush we move
$$(B-B^\epsilon)/B^\epsilon \approx B^{1-\epsilon}$$ elements down to each
children. For a detailed explanation see also Section 2.2. of [Jannen et
al.](https://www.usenix.org/system/files/conference/fast15/fast15-paper-jannen_william.pdf)



| Cost          | B+-tree               | HH-tree                                          |
| ------------- | ---------------       | ---------------                                  |
| insert/delete | $$O(\log_B N)$$       | $$O(\frac{1}{\epsilon B^{1-\epsilon}}\log_B N)$$ |
| query         | $$O(\log_B N)$$       | $$O(\frac{1}{\epsilon} \log_B N)$$               |
| range         | $$O(\log_B N + k/B)$$ | $$O(\frac{1}{\epsilon}\log_B N + k/B)$$          |

<small>Table 1: Comparison of the asymptotic complexity of operations between a
B+-tree and a HH-tree.</small>


Note that while the query costs go slightly up by $$\frac{1}{\epsilon}$$, we can
pick larger node sizes because they are not rewritten as often as is the case
for a B+-tree. If we consider $$\epsilon$$ as a fixed constant, e.g.
$$\frac{1}{2}$$ then it vanishes from the asymptotic cost expressions
completely and yield the theoretic superiority of a fractal tree.


# Persistence

So far we have basically described the fractal tree concept, but we have already
given a hint in Figure 1 that we have a
[merkelized](https://en.wikipedia.org/wiki/Merkle_tree) data structure. This
means we do not overwrite the trees in place, but in fact implement a so called
persistent data structure that returns copies after insertion events and shares
structure as can be seen in Figure 6. The programming language of our choice,
[Clojure](http://clojure.org), puts this decision at the center of its design
and therefore makes the Hitchhiker-tree implementation both straightforward and
very robust to concurrent access.

<div class="center" style="width: 100%"> 
<img src="/images/persistence_annotated.png"> 
<br/>
<small>Figure 6: A tree with elements 1 until 11 and a new tree after the addition of elements 12,13. </small> </div>

## Merkelized Replication

Clojure's data structures can be merkelized fairly easily with
[hasch](https://github.com/replikativ/hasch/). We have exploited this fact and
changed the original Hitchhiker-tree implementation to use cryptographic
[SHA512](https://de.wikipedia.org/wiki/SHA-2) pointers to children of nodes.
Replicating an immutable data structure that way is fairly easy and our
experience with [replikativ](http://replikativ.io) has allowed us to make the
Hitchhiker-tree readily available in our stack. Importantly replication is also
bounded by the same logarithmic properties of the tree, i.e. no element takes
more than $$O(\log_B N)$$ steps to replicate and in aggregate synchronization
behaves more like range queries. This is unachievable by most blockchain systems
today.



# Conclusion

I hope we have explained the background behind the Hitchhiker-Tree so that you
have an understanding why it is a theoretically and practically optimal
datastructure to build distributed databases on top. In its merkelized version
it is in our opinion a far better choice to implement high performing data
storage solutions like blockchains than direct implementations of DAGs or
chains. To make usage convenient we have build on a sound and declarative query
language to leverage the strengths of the Hitchhiker-tree. For this reason we
have ported a [datalog engine](https://github.com/tonsky/datascript/) on top of
it with [datahike](https://github.com/replikativ/datahike).


The hitchhiker-tree is not only the basis for datopia, our Blockchain database.
Making the right decision on the datastructure-level facilitates optimization
and integration between the technologies of our ecosystem and makes composition
of them a breeze. The port of the datalog engine actually just took one of us a
week without being an expert in it. We think that this focus on a [reduction in
complexity is necessary](http://www.infoq.com/presentations/Simple-Made-Easy) to
explore the different performance and design tradeoffs that the universe of
distributed databases and blockchains that lays in front of us. Join us!





