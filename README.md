# Introduction

Since MMX was first introduced in the 90's, x86 CPUs have offered a growing array (I'm not sorry!) of vector functionality. In this homework, we will experiment with one of the more recent vector extensions, AVX512, which offers many powerful packed integer instructions, operating on (up to) 512-bit registers. More specifically, the assignment consists of variations of the problem of finding the smallest value in an array.

## Preliminaries

This homework requires access to a machine with AVX512 extensions, which is available on our the quads1 server. I've made quads1 available to the class, accessible as follows: `ssh -p 8131 bits-head.cs.uic.edu`. As with pages, your UIC netid password applies. For this homework, we are writing single-threaded programs, however, so if your own computer supports AVX512, feel free to use that. Even (shudder) virtual machines could be ok, as long as the host CPU supports AVX512. Watch out: if a researcher is running parallel code on the machine while you are running your program, your performance results could be heavily affected. Before running a performance experiment, take a quick lock with `htop`.

## Getting started

To build the programs, simply run `make` in the checked-out repository folder. For each assignment, only edit the file that contains the min-function in question, leave the main program alone.

### Establish performance baseline, and prepare plots with gnuplot

In `cmin.c`, the implementations of `arraymin()`, and `minindex()` already complete `test_cvec` and `test_novec` without error. While `arraymin()` returns the minimum value, `minindex()` should return the index of the smallest value. Run `benchmark_cvec` and `benchmark_cnovec` to measure the performance of this implementation with and without vectorization.

Using gnuplot, generate a plot of `benchmark_cvec` and `benchmark_cnovec` (four separate, labeled lines), with input size on the x-axis, and cycles/op on the y-axis. Use sizes from 8 to 65536 elements. 

### Iterative Vector Min

In `iterative.c`, implement a vectorized `arraymin()` function using a combination of C and inline assembly.
You may assume that the input size is a multiple of 64 64-bit integers. Similar to what we did in class, use a C for-loop, and an inline assembly loop body using the VPMINSD/SQ instruction to produce a vector of up to 64 values, one of which is the smallest. Then, finish the job after the loop using another chunk of inline assembly, to compute the single minimum value. For this part, consider using a combination of the instructions VPSHUFD, VPERM2I128, VALIGNR.

What's faster, using the 512-bit (zmm) AVX512, the 256-bit (ymm) AVX2 or 128-bit (xmm) AVX instructions? 
Plot cycles/op vs. input size. How does this compare the vectorized C version?
Study the assembly of the vectorized C version and try to determine what causes the difference.

### Iterative Vector Min with Index

In `iterative.c`, implement `minindex()`, another vectorized min function using a combination of C and inline assembly. Here, VPMINSD will not help. Instead, use a combination of VMOVDQA (move), VCMPGTD (compare), VPAND, VPXOR, VPOR, VPADDD, and VPBROADCASTD, and perhaps others.

Here's one approach you can use - there are others.
Start by writing a replacement for the VPMINSD instruction using VCMPGTD (compare), VPAND, and VPOR. Then, add instructions for tracking the index of each of the array minima. Hint: VCMPEQD %ymm0,%ymm0,%ymm0 sets every bit in `ymm0` to 1. VPBROADCASTD puts the same scalar in each integer-sized slot of the a vector register.

For simplicity, you may use C code to compute the final index outside the loop.

Plot cycles/op vs. input size. How does this compare the vectorized C version of `minindex`? 

### Faster, Fixed-Sized Vector Min (bonus)

In `fixed.c`, implement `arraymin()`. Here, the array always has 256 integer elements in it. Write the fastest array min you can come up with, targeting Skylake-X, using one big block of inline assembly, no branches, no loops. Here, feel free to make use of VPMINSD/SQ, and anything else you want to try.

Once `test_fixed` runs without error, announce your best `benchmark_fixed` performance on Piazza.

Hint: keep data dependencies, instruction latency and reciprocal throughput in mind. Check Agner Fog's tables for Skylake-X.
Measure and share performance in cycles/op.