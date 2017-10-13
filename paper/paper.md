---
title: "_quiho_: Sensitivity Analysis of Applications for Discovering 
Hardware Factors Affecting Performance"
author:
- name: "  "
  affiliation: "  "
  email: "  "
abstract: |
  We introduce quiho, a framework for discovering hardware and system 
  software bottlenecks that influence the performance of an 
  application. We do this by applying sensitivity analyisis 
  (regression) using hardware-independent feature vectors.
documentclass: ieeetran
ieeetran: true
classoption: "conference,compsocconf"
monofont-size: scriptsize
numbersections: true
usedefaultspacing: true
fontfamily: times
linkcolor: cyan
urlcolor: cyan
secPrefix: section
---


# Introduction

Understanding the effects in performance that distinct hardware and 
low-level system software[^system] components have on applications is 
a challenging endeavor.

**TODO**: find references

Identifying bottlenecks is an essential part of performance 
engineering. By monitoring an application, one can understand which 
parts of the system an application is hammering on.

**TODO**: find references

Fine granularity bottlenecks are even more important because they 
allow application developers and performance engineers to quickly 
understand what they need to focus on while refactoring an 
application.

**TODO**: find references. If possible, show a scenario where fine 
granularity bottleneck detection is useful (e.g. showing how an 
engineer might want to refactor an application in the "wrong" 
section).

**TODO**: double-check, are we addressing Jay's points:

> The pitch overall does not sell why they need to care about 
fine-granularity bottlenecks well enough. I can see what they are 
based on the description, but there isn't an argument that explains 
why they are worth dealing with or tracking down. Some sense of the 
impact is needed to make readers care about the contributions. As you 
explain, they are lesser than what is there already. How much 
performance is left on the table by not addressing these? Why can't 
these be identified sufficiently well by existing profiling tools? 
Yes, they span areas, but can't they be identified well enough to be 
addressed?

Traditionally, coarse-grained bottlenecks (i.e. CPU-, memory- or 
IO-bound) can be obtained by monitoring an application's resource 
utilization over time.

**TODO**: find references

Fine granularity bottlenecks associated to other system subcomponents 
such as the OS memory mapping submodule or the CPU's cryptographic 
unit are harder to find, and usually involve eyeballing source code, 
static code analysis, or analyzing hardware/OS performance counters.

**TODO**: find references

An alternative is to infer a bottleneck by comparing the performance 
(e.g. runtime) of the same software stack (OS + application) on 
platforms with different hardware characteristics. For example, if we 
know that machine A has higher memory bandwidth than machine B, and an 
application is memory-bound, then this application will perform better 
on machine A. This approach presents three challenges:

  1. Is difficult to obtain the performance characteristics of a 
     machine by just looking at the hardware spec, so other more 
     practical alternative is required. For example, the spec might 
     specify that the machine has DDR4 memory sticks, with a 
     theoretical peak throughput of XX GB/s, but the actual memory 
     bandwidth is likely to be less than this.
  2. We need to ensure that the software stack is the same on all 
     machines where the application runs.
  3. The amount of effort required to run applications on a multitude 
     of platforms is not negligible.

In this work, we present _quiho_[^name], a framework that can be used 
to automatically detect fine-granularity system bottlenecks by 
systematically addressing the 3 challenges outlined above this 
approach.

**TODO:brief intro to quiho:
  * performance vectors
  * feature importance in linear regression
  * insight: feature importance => bottleneck detection**

Contributions:

  * Application-agnostic method for quantifying system performance.
  * Insight: feature importance of regression models (trained using 
    the performance vectors) gives us bottlenecks for applications 
    without looking at the code.
  * Methodology for evaluating bottleneck detection. Since we can 
    control where the bottleneck of an application is, this method 
    works for any other type of bottleneck detection, not just 
    _quiho_.

<!--
  * Popper templates for CloudLab/Chameleon as an outcome of our 
    experimental evaluation.
-->

Practical applications of _quiho_:

  * complement performance regression. i.e. as part of performance 
    regression analysis, the feature importance profile of an 
    application has to resemble the one of a previous version.

  * aid in performance engineering / analysis. When analyzing any 
    performance degradation of an application, then the feature 
    importance profile can be used as a "pointer" to where to start 
    with the investigation. For example, if _memorymap_ ends up being 
    the most important feature, then we can start by looking at any 
    code/libraries related to this functionality.

  * stopping condition in uncertainty quantification (UQ), or 
    parameter space exploration. When studying the performance 
    landscape of an application with respect to its parameter space, 
    we can use _quiho_ as a stopping condition to prune the space 
    (e.g. if multiple, relatively "apart" values for the same 
    parameter result in the same bottleneck, then it's unlikely this 
    won't change for other values of that same parameter).

[^system]: throughout this paper, we use "system" to refer to 
hardware, firmware and the operating system (OS).

[^name]: the word _quiho_ means "to discover" or "to find" in the Seri 
dialect, a native tribe from northwest Mexico.

# The _quiho_ Sensitivity Analysis Framework

Either here or in the intro, give a high-level overview of the entire 
thing. This has to explain intuition behind quiho:
  * performance vectors from stress-ng
  * feature selection implies bottleneck detection.

**TODO**: Add diagram of steps

# Performance Feature Vectors As System Performance Characterization

While the hardware and software specification can serve to describe 
the performance characteristics of a machine, the real performance 
characteristics can only feasibly[^feasible] be obtained by executing 
programs and capturing metrics. The question then boils down to which 
programs should we use to characterize performance? Ideally, we would 
like to have many programs that execute every possible opcode mix so 
that we measure their performance. Since this is an impractical 
solution, an alternative is to create synthetic microbenchmarks that 
get as close as possible to exercising all the available features of a 
system.

[^feasible]: One can get generate arbitrary performance 
characteristics by interposing a hardware emulation layer and 
deterministically associate performance characteristics to each 
instruction based on specific hardware specs. While possible, this is 
impractical (we are interested in characterizing "real" performance).

[`stress-ng`](http://kernel.ubuntu.com/~cking/stress-ng) is a tool 
that is used to "stress test a computer system in various selectable 
ways. It was designed to exercise various physical subsystems of a 
computer as well as the various operating system kernel interfaces". 
There are multiple stressors for CPU, CPU cache, memory, OS, network 
and filesystem. Since we focus on system performance bandwidth, we 
execute the (as of version 0.07.29) 42 stressors for CPU, memory and 
virtual virtual memory stressors. A "stressor" is a routine that loops 
a function  multiple times and reports the rate of iterations executed 
for a determined period of time (referred to as 
`bogo-ops-per-second`).

![Feature vectors.
](figures/performance_feature_vectors.png){#fig:perf-vectors}

Using this battery of stressors, one can obtain a performance profile 
of a machine. When this profile is compared against the profile of 
another machine, we can quantify the difference in performance between 
the two. @Fig:corrmatrix shows the correlation matrix of stressors for 
all the distinct machine configurations available in CloudLab 
[@ricci_introducing_2014] (@Tbl:machines shows a summary of hardware 
specs). Every stressor can be mapped to basic features of the 
underlying platform. For example, `stream` to memory bandwidth, `zero` 
to memory mapping, `qsort` to sorting data, etc.

\begin{table}\caption{\label{tbl:machines} List of machines and hardware 
characteristics used in this paper.}
\input{figures/machines_table.tex}
\end{table}

![Correlation matrix of all stressors
](figures/corrmatrix.png){#fig:corrmatrix}

# Bottlenecks Detection Via Feature Importance in Regression Models

The performance of an application is determined by the performance of 
the subcomponents that get stressed the most by the application's 
code. Thus, intuitively, if the performance of an application across 
multiple machines resembles the . In @Sec:eval we empirically validate 
this. In this section we explain the regression technique used.

## Linear Regression

Linear regression:

  * generic regression
  * gradient boosting trees
  * normalization

# Evaluation {#sec:eval}

**Methodology** - For every workload:

  1. Discover relevant features using quiho.
  2. Analyze code to corroborate that discovered features are indeed 
     the cause of performance differences.

# Related Work {#sec:related}

There exists related work, currently compiling and reading it.

# Conclusion and Future Work {#sec:conclusion}

Future:
  * multi-node
  * minimum number of machines?
  * single machine?
  * long-running (multi-stage) applications. e.g. a web-service or 
    big-data application with multiple stages. In this case, we would 
    define windows of time and we would apply quiho to each. The 
    challenge: how do we automatically get the windows rightly placed.

**Acknowledgments**: This work was partially funded by the Center for 
Research in Open Source Software[^cross], Sandia National Laboratories 
and NSF Awards #1450488.

[^cross]: http://cross.ucsc.edu

# Bibliography

<!-- hanged biblio -->

\noindent
\vspace{-2em}
\setlength{\parindent}{-0.26in}
\setlength{\leftskip}{0.2in}
\setlength{\parskip}{8pt}
