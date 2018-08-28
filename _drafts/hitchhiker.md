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

- optimal building block for composed distributed datastructures

- what kind of datastructure to build distributed databases of?

> The goal of the hitchhiker tree is to wed three things: the query performance of
> a B+ tree, the write performance of an append-only log, and convenience of a
> functional, persistent datastructure. Let's look at each of these in some
> detail.

[Hitchhiker-tree motivation](https://github.com/datacrypt-project/hitchhiker-tree/blob/master/doc/hitchhiker.adoc)



# A guide to hitchhike on trees

In this section we first build up some common notions about trees and then guide
you to the design of the hitchhiker tree. 

The simplest tree datastructure for storing a sorted collection of entries is
the [binary tree](https://en.wikipedia.org/wiki/Binary_tree). But it is not
optimal for data retrieval because such a tree can become arbitrarily deformed.
In the worst case it just becomes a [linked
list](https://en.wikipedia.org/wiki/Linked_list). A tree is hence [defined to be
balanced](https://en.wikipedia.org/wiki/Self-balancing_binary_search_tree) if
all leaves have approximately the same distance to the root.

TODO Footnote: Cormen as standard literature.

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
[B-trees](https://en.wikipedia.org/wiki/B-tree). In fact they do one more tweak,
they only store index information in the tree and put all data to the leaf
nodes, which is a so called [B+ tree](https://en.wikipedia.org/wiki/B%2B_tree).
This ideally allows to keep all index nodes in memory and only read the data
nodes from disk as they are much bigger.

<div class="thumbnail-right" style="width: 100%">
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
up the details about the operations in TODO Cormen or on Wikipedia.

## Append log

What is the fastest way to write data? Just append it to a list of which you
know its end. Unsurprisingly this is called an append-log and has write
complexity $$O(1)$$. Unfortunately to retrieve data you have to walk along the
linked list, so an append-log is not optimal to retrieve data and takes $$O(N)$$
steps to retrieve an element. Note that you can immediately see from the big-O
notation that this is significantly worse than the B+ tree.

Figure: append-log ?


## Fractal combination

<div class="thumbnail-right" style="width: 100%">
<img src="/images/hh_tree_annotated.png">
<small>Figure 2: Fractal-Tree</small>
</div>

In Figure 2 you can see a fractal combination of a B+ tree and an append log.
[David has described](https://github.com/datacrypt-project/hitchhiker-tree/blob/master/doc/hitchhiker.adoc) this concept as follows:

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


TODO rewrite parts (?)



## illustrate insertion

TODO Footnote: We would like to add here that while the amortized cost is much
better for the fractal tree, and this is what we care about, the worst case
insertion time is still $$O(\log_B N)$$. Assuming we branch with factor
$$\sqrt{B}$$ yielding half the node-size for the B+ tree and half of it for the
append-log we even get a worsening constant factor as $$O( \frac{\log
B}{\sqrt{B} \log B} \log_B N)$$. The probability that this event occurs is
astronomically small though. TODO

But amortized:
https://www.usenix.org/system/files/conference/fast15/fast15-paper-jannen_william.pdf
Section 2.2



## illustrate query



## persistence data structures

- do path copying
- illustrate path

## Merkelization

- trivial to merkelize Clojure datastructures with hasch


# related work

- fractal tree; log merge structure tree
- tokutek

> The improved write performance is made possible thanks to the same buffering
> technique as a https://en.wikipedia.org/wiki/Fractal_tree_index[fractal tree
> index]. As it turns out, after I implemented the fractal tree, I spoke with a
> former employee of Tokutek, a company that commercialized fractal tree
> indices. That person told me that we'd actually implemented fractal reads
> identically!



# Implementation

- merits of a functional language: Clojure; composition of persistent datastructures
- functional hitchhiking


# conclusion

- datahike, datopia




# Context

## prior knowledge
- assume knowledge of what a datastructure is
- assume knowledge of binary tree (?)


# Outline of: https://www.youtube.com/watch?v=jdn617M3-P4

- Greenberg Video: green allocation, red deallocation, black still same
- pointers: angle brackets
- apple, mango, banana example: linked list
- depth L algebra error (?)
- CLRS book
- increase branching factor
- going wide -> constant speed ups
- 3 levels to demonstrate hitchhiker-tree
- walking through insertion
- projecting pending operations for scan only in range
- hitchhiker: path copying
- sidenote: hitchhiker tree optimized for high-latency IO 32:00 (?)
- flush control
- only flush costs 5 only once (?)
- fan out: 100 vs. 200
- pluggable: storage backend, I/O management, serialization, sorting

- binary search tree
- b tree
- b+ tree
- hitchhiker tree
- path copying

