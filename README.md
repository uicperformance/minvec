# Introduction

Since MMX was first introduced in the 90's, x86 CPUs have offered a growing array (I'm not sorry!) of vector functionality. In this homework, we will experiment with one of the more recent vector extensions, AVX512, which offers many powerful packed integer instructions, operating on (up to) 512-bit registers. More specifically, the assignment consists of variations of the problem of finding the smallest value in an array.

## Preliminaries

This homework requires access to a machine with AVX512 extensions, which is available on our the quads1 server. I've made quads1 available to the class, accessible as follows: `ssh -p 8131 bits-head.cs.uic.edu`. As with pages, your UIC netid password applies. For this homework, we are writing single-threaded programs, however, so if your own computer supports AVX512, feel free to use that. Even (shudder) virtual machines could be ok, as long as the host CPU supports AVX512. Watch out: if a researcher is running parallel code on the machine while you are running your program, your performance results could be heavily affected. Before running a performance experiment, take a quick lock with `htop`.

## Getting started

To build the programs, simply run `make` in the checked-out repository folder. For each assignment, only edit the file that contains the min-function in question, leave the main program alone.

### Establish performance baseline, and prepare plots with gnuplot

In `cmin.c`, the implementations of `arraymin()`, and `minindex()` already complete `test_vec` and `test_novec` without error. While `arraymin()` returns the minimum value, `minindex()` should return the index of the smallest value. Run `benchmark_vec` and `benchmark_novec` to measure the performance of this implementation with and without vectorization.

Using gnuplot, generate a plot of `benchmark_vec` and `benchmark_novec` (four separate, labeled lines), with input size on the x-axis, and cycles/op on the y-axis. Use sizes from 8 to 65536 elements. 

### Iterative Vector Min

In `iterative.c`, implement a vectorized `arraymin()` function using a combination of C and inline assembly (or, if you prefer, C vector intrinsics).
You may assume that the input size is a multiple of 64 64-bit integers. Similar to what we did in class, use a C for-loop, and an inline assembly loop body using the VPMINSD/SQ (sometimes this appears to be called VMINSD instead) instruction to produce a vector of up to 64 values, one of which is the smallest. Then, finish the job after the loop using another chunk of inline assembly, to compute the single minimum value. For this part, consider using a combination of the instructions VPSHUFD, VPERM2I128, VALIGNR.  

What's faster, using the 512-bit (zmm) AVX512, the 256-bit (ymm) AVX2 or 128-bit (xmm) AVX instructions? 
Plot cycles/op vs. input size. How does this compare the vectorized C version?
Study the assembly of the vectorized C version and try to determine what causes the difference.

### Iterative Vector Min with Index

In `iterative.c`, implement `minindex()`, another vectorized min function using a combination of C and inline assembly. Here, VPMINSD will not help. Instead, use a combination of VMOVDQA (move), VCMPGTD (compare), VPAND, VPXOR, VPOR, VPADDD, and VPBROADCASTD, and perhaps others.

Here's one approach you can use - there are others.
Start by writing a replacement for the VPMINSD instruction using VCMPGTD (compare), VPAND, and VPOR. Then, add instructions for tracking the index of each of the array minima. Hint: VCMPEQD %ymm0,%ymm0,%ymm0 sets every bit in `ymm0` to 1. VPBROADCASTD puts the same scalar in each integer-sized slot of the a vector register.

For simplicity, you may use C code to compute the final index outside the loop.

Plot cycles/op vs. input size. How does this compare the vectorized C version of `minindex`? 

### Multi-Threaded Vector Min 

Having introduced optimized vector code, we've done all we can do on a single core. To go faster, we need the resources of additional cores, which is only available through multi-threading. 

For this part, there is the added complexity of a mutator thread, which makes frequent "transfers" between array elements: it adds some number $x$ to one element, and subtracts the same $x$ from another element. To ensure consistency, the mutator thread requires exclusive access to the relevant array elements during these transfers.

The `mtbench.c` program runs the mutator thread as well as a variable number of threads computing array minima. The benchmark program in turn computes, checks and reports the minimum of the minima returned from the threads. 

For this part, you may modify `mtbench.c`, to improve the synchronization behavior of the program. Specifically, you may want to modify the `scanner_thread` and `mutator_thread` functions. 

As a first step, we will improve the performance without a running mutator (binary `mtbench_nomut`).

#### Use the right lock for the job

In the template design, worker threads acquire the global lock before computing the minimum. This is necessary for correctness when the mutator thread runs. However, it's not very practical, since the workers end up working in sequence rather than in parallel, negating the benefits of multithreading. 

Try switching to a single readers-writer lock `pthread_rwlock` instead, in which multiple readers can hold a single lock at the same time. Run `mtbench_nomut` to observe the performance difference between mutex and rwlock. 

#### Eliminate Redundancy

The template implementation does redundant work on all threads, resulting in no speedup. Instead, we should be dividing up the work between the threads.
Here are a few different ways to divide up the work between N threads: 

 * divide up the array into N contiguous sets of elements, one set per thread (sharded),
 * have each thread process every N elements (interleaved) or, more generally
 * have each thread process k elements spaced every kN elements (block interleaved)

There may be other ways as well. Some questions to explore: 

* Which of the sharded and interleaved cases do you expect to be faster?
* For the block interleaved case, is there a range of `k` that you think may be better/worse than others?
* Is the block interleaved faster/slower than the sharded case for all `k`?

Don't guess, work out a hypothesis and a prediction. Then test it with an experiment.

As mentioned before, if you make a precise prediction ("minor time difference, within 1%", "25% faster for k between 4 and 8"), a positive outcome is good evidence in support of your hypothesis. If it's a weak prediction ("takes longer", "more cache misses"), it's much more likely that to be coincidence. 

#### Consider *not* multi-threading

For small problems, it can be much faster to not incur the overhead of launching multiple threads, and simply completing the work on a single thread. You could consider going with single-threaded readers for small problems.

#### Consider keeping the threads alive

Another approach that can be very fruitful for shorter jobs is not starting new threads every time, but instead waking up existing threads. In the template, we already use a barrier for synchronization. A similar barrier could be used by threads waiting for their next job. 

#### Improve Locking with a Writer in the mix

The mutator thread performs transfers periodically, with a frequency that increases over the duration of a run. 
If any one transaction fails to finish before the next was meant to begin (i.e. the latency was greater than the period), the execution terminates. 

If the mutator period is shorter than the time it takes for the workers to finish their job, therefore, we must ensure that the writer gets a chance to perform its updates before the workers are done. 

In the template, the mutator thread holds the global lock during each transfer, meaning it can't do anything while the readers scan the array. We need a different locking scheme. Here are some ideas:

* have readers periodically release and reaquire the lock
* split the array into several shards, and have a lock per shard
* a lock per array item, instead of a single lock for the whole array

For longer critical sections, a readers-writer lock might work best. For a lock per individual item, you certainly want to use a spinlock. In all cases, make sure that the mutator maintains mutual exclusion over the two elements it is updating in any one transfer, so that the reader threads cannot read an inconsistent result.

*Note:* There is no test case to verify the accuracy of the minimum you compute, so it's your responsibility to make sure the readers hold the appropriate locks to access whatever elements they end up accessing. 

The `mtbench` program outputs a score, which is the product of the maximum viable update frequency, the achieved scan rate, and the size of the table. What's your best score?



