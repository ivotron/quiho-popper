---
title: "_quiho_: Automated Performance Regression Using Fine 
Granularity Resource Utilization Profiles"
author:
- name: Ivo Jimenez
  affiliation: UC Santa Cruz
  email: ivo.jimenez@ucsc.edu
- name: Jay Lofstead
  affiliation: Sandia National Laboratories
  email: gflofst@sandia.gov
- name: Carlos Maltzahn
  affiliation: UC Santa Cruz
  email: carlosm@ucsc.edu
abstract: |
  We introduce _quiho_, a framework used in automated performance 
  regression tests. _quiho_ discovers hardware and system software 
  resource utilization patterns that influence the performance of an 
  application. It achieves this by applying sensitivity analyisis, in 
  particular statistical regression analysis (SRA), using 
  application-independent performance feature vectors to characterize 
  the performance of machines. The result of the SRA, in particular 
  feature importance, is used as a proxy to identify hardware and 
  low-level system software behavior. The relative importance of these 
  features serve as a performance profile of an application, which is 
  used to automatically validate its performance behavior across 
  revisions. We demonstrate that _quiho_ can successfully identify 
  performance regressions by showing its effectiveness in profiling 
  application performance for synthetically induced regressions as 
  well as several found in real-world applications.
---

# Introduction

Quality assurance (QA) is an essential activity in the software 
engineering process [@myers_art_2011 ; @bertolino_software_2007 ; 
@beizer_software_1990]. Part of the QA pipeline involves the execution 
of performance regression tests, where the performance of the 
application is measured and contrasted against past versions 
[@dean_tail_2013 ; @gregg_systems_2013 ; @vokolos_performance_1998]. 
Examples of metrics used in regression testing are throughput, 
latency, or resource utilization over time. These metrics are compared 
and when significant differences are found, this constitutes a 
regression.

One of the main challenges in performance regression testing is 
defining the criteria to decide whether a change in an application's 
performance behavior is significant, that is, whether a regression has 
occurred [@cherkasova_anomaly_2008]. Simply comparing values (e.g. 
runtime) is not enough, even if this is done in statistical terms 
(e.g. mean runtime within a pre-defined variability range). 
Traditionally, this investigation is done by an analyst in charge of 
looking at changes, possibly investigating deeply into the issue and 
finally determining whether a regression exists.

When investigating a candidate of a regression, one important task is 
to find bottlenecks [@ibidunmoye_performance_2015]. Understanding the 
effects in performance that distinct hardware and low-level system 
software[^system] components have on applications is an essential part 
of performance engineering [@jin_understanding_2012 ; 
@han_performance_2012 ; @jovic_catch_2011]. One common approach is to 
monitor an application's performance in order to understand which 
parts of the system an application is hammering on
[@gregg_systems_2013]. Automated solutions have been proposed 
[@cherkasova_anomaly_2008; @jiang_automated_2010 ; 
@shang_automated_2015 ; @heger_automated_2013]. The general approach 
of these is to analyze logs and/or metrics obtained as part of the 
execution of an application in order to automatically determine 
whether a regression has occurred. Most of them do this by creating 
prediction models that are checked against the runtime metrics. As 
with any prediction model, there is the risk of false/positive 
negatives **TODO: expand; put quiho in context**.

In this work, we present _quiho_ an approach aimed at complementing 
automated performance regression testing by using system resource 
utilization profiles associated to an application. A resource 
utilization profile is obtained using Statistical Regression 
Analysis[^sra] (SRA) where application-independent performance feature 
vectors are used to characterize the performance of machines. The 
performance of an application is then analyzed applying SRA to build a 
model for predicting its performance, using the performance vectors as 
the independent variables and the application performance metric as 
the dependant variable. The results of the SRA for an application, in 
particular feature importance, is used as a proxy to characterize 
hardware and low-level system utilization behavior. The relative 
importance of these features serve as a performance profile of an 
application, which is used to automatically validate its performance 
behavior across multiple revisions of its code base.

In this article, we demonstrate that _quiho_ can successfully identify 
performance regressions. We show (@Sec:eval) that _quiho_ (1) obtains 
resource utilization profiles for application that reflect what their 
codes do and (2) effectively uses these profiles to identify induced 
regressions as well as other regressions found in real-world 
applications. The contributions of our work are:

  * A method for quantifying system performance via microbenchmark 
    performance vectors.
  * Insight: feature importance in SRA models (trained using these 
    performance vectors) gives us a resource utilization profile of an 
    application without having to look at the code.
  * Methodology for evaluating automated performance regression. We 
    introduce a set of synthetic benchmarks aimed at evaluating 
    automated regression without the need of real repositories. These 
    benchmarks take as input parameters that determine their 
    performance behavior, thus simulating different "versions" of an 
    application.
  * A negative result: ineffectiveness of resource utilization 
    profiles for predicting performance.

We give an overview SRA in @Sec:sra and its use in both, bottleneck 
identification as well as in performance regression testing. We then 
show the intuition behind _quiho_ and how can be used to automate 
regression tests (@Sec:intuition). We then do a more in-depth 
description of _quiho_ (@Sec:quiho), followed by our evaluation of 
this approach (@Sec:eval). We briefly show how _quiho_'s resource 
utilization profiles can not be used to predict performance using some 
common machine learning techniques (@Sec:negative). We then close with 
a brief discussion on challenges and opportunities enabled by _quiho_ 
(@Sec:conclusion).

[^system]: Throughout this paper, we use "system" to refer to 
hardware, firmware and the operating system (OS).
[^name]: The word _quiho_ means "to discover" or "to find" in Seri, a 
dialect from a native tribe of the same name from Northwestern Mexico.
[^sra]: We use the term _Statistical Regression Analysis_ (SRA) to 
differentiate between "traditional" regression analysis in software 
engineering and regression analysis in statistics.

# Statistical Regression Analysis in Software Testing {#sra}

SRA is an approach for modeling the relationship between variables, 
usually corresponding to observed data points 
[@freedman_statistical_2009]. One or more independent variables are 
used to obtain a _regression function_ that explains the values taken 
by a dependent variable. A common approach is to assume a _linear 
predictor function_ and estimate the unknown parameters of the modeled 
relationships.

## Anomaly Detection and Bottleneck Identification

It's been used in bottleneck detection both
[@ibidunmoye_performance_2015]. **TODO: mention briefly how it is 
used**.

## Automated Regression Testing

In [@shang_automated_2015], they use it to detect regressions using a 
dataset of performance counters.

# Motivation {#intuition}

**TODO: show a diagram with an automated testing loop and show where 
quiho is placed**

Traditionally, coarse-grained resource utilization (i.e. CPU-, memory- 
or IO-bound) can be obtained by monitoring an application's resource 
utilization over time. Fine granularity behavior allows application 
developers and performance engineers to quickly understand what they 
need to focus on while refactoring an application.

Fine granularity performance behavior, for example,  system 
subcomponents such as the OS memory mapping submodule or the CPU's 
cryptographic unit are harder to find, and usually involve eyeballing 
source code, static code analysis, or analyzing hardware/OS 
performance counters.

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

# Our Approach

In this section we describe:

  * Performance vectors to characterize behavior
  * Using these to build SRA models for application performance.
  * Feature importance in SRA models gives us resource utilization 
    profiles.

## Performance Feature Vectors As System Performance Characterization

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

![Correlation matrix of performance vectors.
](figures/corrmatrix.png){#fig:corrmatrix}

Using this battery of stressors, one can obtain a performance profile 
of a machine. When this profile is compared against the profile of 
another machine, we can quantify the difference in performance between 
the two. @Fig:corrmatrix shows the correlation matrix of stressors for 
all the distinct machine configurations available in CloudLab 
[@ricci_introducing_2014] (<!--@Tbl:machines--> shows a summary of 
hardware specs). Every stressor can be mapped to basic features of the 
underlying platform. For example, `stream` to memory bandwidth, `zero` 
to memory mapping, `qsort` to sorting data, etc.

<!--
\begin{table}\caption{\label{tbl:machines} List of machines and hardware 
characteristics used in this paper.}
\input{figures/machines_table.tex}
\end{table}

![Correlation matrix of all stressors
](figures/corrmatrix.png){#fig:corrmatrix}
-->

## System Resource Utilization Via Feature Importance in Regression Models

The performance of an application is determined by the performance of 
the subcomponents that get stressed the most by the application's 
code. Thus, intuitively, if the performance of an application across 
multiple machines resembles the . In @Sec:eval we empirically validate 
this. In this section we explain the regression technique used.

Linear regression:

  * generic regression
  * gradient boosting trees
  * normalization

# Evaluation {#sec:eval}

This section we demonstrate:

  * resource utilization profiles (RUP) accurately capture application 
    performance behavior.
  * RUPs work for synthetic workloads.
  * RUPs work for "real" regressions.

This paper adheres to The Popper Experimentation Protocol[^popper-url] 
[@jimenez_popper_2017], so experiments presented here are available in 
the repository for this article[^gh]. Experiments can be examined in 
more detail, or even re-executed, by visiting the `[source]` link next 
to each figure. That link points to a Jupyter notebook that shows the 
analysis and source code for that graph, which points to an experiment 
and its artifacts.

## Performance Profiles

We show they actually show the performance of known benchmarks.


**Methodology** - For every workload:

  1. Discover relevant features using quiho.
  2. Analyze code to corroborate that discovered features are indeed 
     the cause of performance differences.

## Simulating Regressions

We show that if we simulate regressions, then _quiho_ identifies them 
correctly.

## Real-world Scenarios

We show that _quiho_ works with real regressions. Systems:

  * zlog
  * mariadb
  * apache commons math
  * gcc

[^popper-url]: http://falsifiable.us
[^gh]: http://github.com/ivotron/quiho-popper

## _quiho_ cannot predict performance {#sec:negative}

We show how _quiho_ does not do a good job at predicting performance.

# Conclusion and Future Work {#sec:conclusion}

In the not-so-distant future:

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

# References {.unnumbered}

<!-- hanged biblio -->

\noindent
\vspace{-1em}
\setlength{\parindent}{-0.175in}
\setlength{\leftskip}{0.2in}
\setlength{\parskip}{0.5pt}
\fontsize{7pt}{8pt}\selectfont
