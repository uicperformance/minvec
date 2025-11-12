# Introduction

Since MMX was first introduced in the 90's, x86 CPUs have offered a growing array (I'm not sorry!) of vector functionality. In this homework, we will experiment with one of the more recent vector extensions, AVX512, which offers many powerful packed integer instructions, operating on (up to) 512-bit registers. More specifically, the assignment consists of variations of the problem of finding the smallest value in an array.

## Preliminaries

This homework requires access to a machine with AVX512 extensions, which is available on our the quads1 server. I've made quads1 available to the class, accessible as follows: `ssh -p 8131 bits-head.cs.uic.edu`. As with nodes, your UIC netid password applies. For this homework, we are writing single-threaded programs, however, so if your own computer supports AVX512, feel free to use that. Even (shudder) virtual machines could be ok, as long as the host CPU supports AVX512. Watch out: if a researcher is running parallel code on the machine while you are running your program, your performance results could be heavily affected. Before running a performance experiment, take a quick lock with `htop`.

## Getting started

To build the programs, simply run `make` in the checked-out repository folder. For each assignment, only edit the file that contains the min-function in question, leave the main program alone.

### Establish performance baseline, and prepare plots with gnuplot

In `cmin.c`, the implementations of `arraymin()`, and `minindex()` already complete `test_vec` and `test_novec` without error. While `arraymin()` returns the minimum value, `minindex()` should return the index of the smallest value. Run `benchmark_vec` and `benchmark_novec` to measure the performance of this implementation with and without vectorization.

Using gnuplot, generate a plot of `benchmark_vec` and `benchmark_novec` (four separate, labeled lines), with input size on the x-axis, and cycles/op on the y-axis. Use sizes from 8 to 65536 elements. 

Try using `set logscale y` and `set logscale xy` in gnuplot to see the details for small sizes better. 

- what do you notice about the relative performance of the vec and novec solutions?
- compare the produced assembly for both _vec and the _novec solutions. Read each carefully to understand how it works. 
- the arraymin _vec solution is slow (per element) for small vectors, then very fast for medium size vectors, then slower again for large vectors. What explains this? Why does the _novec solution
not show a similar trend? Try using performance tools to investigate.

### Iterative Vector Min

Initially, `iterative.c` is identical to `cmin.c`.

In `iterative.c`, implement a vectorized `arraymin()` function using a combination of C and inline assembly (or, if you prefer, C vector intrinsics).
You may assume that the input size is a multiple of 64 32-bit integers. Similar to what we did in class, use a C for-loop, and an inline assembly loop body using the VPMINSD (sometimes this appears to be called VMINSD instead) instruction to produce a vector of up to 64 values, one of which is the smallest. Then, finish the job after the loop using another chunk of inline assembly, to compute the single minimum value. For this part, consider using a combination of the instructions VPSHUFD, VPERM2I128, VALIGNR.  

- Plot cycles/op vs. input size for your version and the C version.
- What's faster, using the 512-bit (zmm) AVX512, the 256-bit (ymm) AVX2 or 128-bit (xmm) AVX instructions? You can try specifying the available instruction set to gcc with `-m`, or with clang `-mprefer-vector-width` to force the compiler to produce different versions.
- How does your version compare the vectorized C version?
- Study the assembly of the vectorized C version and try to determine what causes the difference.

### Iterative Vector Min with Index

In `iterative.c`, implement `minindex()`, another vectorized min function using a combination of C and inline assembly. Here, VPMINSD will not help. Instead, use a combination of VMOVDQA (move), VCMPGTD (compare), VPAND, VPXOR, VPOR, VPADDD, and VPBROADCASTD, and perhaps others.

Here's one approach you can use - there are others.
Start by writing a replacement for the VPMINSD instruction using VCMPGTD (compare), VPAND, and VPOR. Then, add instructions for tracking the index of each of the array minima. Hint: VCMPEQD %ymm0,%ymm0,%ymm0 sets every bit in `ymm0` to 1. VPBROADCASTD puts the same scalar in each integer-sized slot of the a vector register.

For simplicity, you may use C code to compute the final index outside the loop.

- Plot cycles/op vs. input size. How does this compare the vectorized C version of `minindex`? 
- How fast can you get this? My solution runs just under 0.6 cycles per element. 

