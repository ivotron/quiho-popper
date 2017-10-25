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
prediction models that are checked against runtime metrics. As with 
any prediction model, there is the risk of false/positive negatives.

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

  * Insight: feature importance in SRA models (trained using these 
    performance vectors) gives us a resource utilization profile of an 
    application without having to look at the code.
  * Methodology for evaluating automated performance regression. We 
    introduce a set of synthetic benchmarks aimed at evaluating 
    automated regression testing without the need of real bug 
    repositories. These benchmarks take as input parameters that 
    determine their performance behavior, thus simulating different 
    "versions" of an application.
  * A negative result: ineffectiveness of resource utilization 
    profiles for predicting performance using ensemble learning.

Next section (@Sec:intuition) shows the intuition behind _quiho_ and 
how can be used to automate regression tests (@Sec:intuition). We then 
do a more in-depth description of _quiho_ (@Sec:quiho), followed by 
our evaluation of this approach (@Sec:eval). We briefly show how 
_quiho_'s resource utilization profiles can not be used to predict 
performance using some common machine learning techniques 
(@Sec:negative). @Sec:sra reviews related work and we subsequently 
close with a brief discussion on challenges and opportunities enabled 
by _quiho_ (@Sec:conclusion).

[^system]: Throughout this paper, we use "system" to refer to 
hardware, firmware and the operating system (OS).
[^name]: The word _quiho_ means "to discover" or "to find" in Seri, 
the dialect of a native tribe of the same name from Northwestern 
Mexico.
[^sra]: We use the term _Statistical Regression Analysis_ (SRA) to 
differentiate between regression testing in software engineering and 
regression analysis in statistics.

# Motivation and Intuition Behind _quiho_ {#sec:intuition}

@Fig:pipeline shows the workflow of an automated regression testing 
pipeline and shows how _quiho_ fits in this picture.

![Automated regression testing pipeline integrating fine granularity 
resource utilization profiles (FGRUP). FGRUPs are obtained by _quiho_ 
and can be used both, for identifying regressions, and to aid in the 
quest for finding the root cause of a regression.
](figures/pipeline.png){#fig:pipeline}

A regression is usually the result of observing a significant change 
in a performance metric of interest (e.g. runtime). At this point, an 
analyst will investigate further in order to find the root cause of the 
problem. One of these activities involves profiling an application to see 
what's the patter in terms of resource utilization. Traditionally, 
coarse-grained profiling (i.e. CPU-, memory- or IO-bound) 
can be obtained by monitoring an application's resource utilization 
over time. Fine granularity behavior allows application developers and 
performance engineers to quickly understand what they need to focus on 
while refactoring an application.

Obtaining fine granularity performance utilization behavior, for 
example, system subcomponents such as the OS memory mapping submodule 
or the CPU's cryptographic unit is usually time-consuming or requires 
implicates the use of more computing resources. This usually involves 
eyeballing source code, static code analysis, or analyzing hardware/OS 
performance counters.

An alternative is to infer fine granularity resource utilization 
behavior by comparing the performance of an application on platforms 
with different system performance characteristics. For example, if we 
know that machine A has higher memory bandwidth than machine B, and an 
application is memory-bound, then this application will perform better 
on machine A. There are several challenges with this approach:

 1. We need to ensure that the software stack is the same on all 
    machines where the application runs.
 2. The amount of effort required to run applications on a multitude 
    of platforms is not negligible.
 3. It is difficult to obtain the performance characteristics of a 
    machine by just looking at the hardware spec, so other more 
    practical alternative is required..
 4. Even if we could solve 3 and infer performance characteristics by 
    just looking at the hardware specification of a machine, there is 
    still the issue of not being able to correlate baseline 
    performance with application behavior, since between two platforms 
    is rarely the case where the change of performance is observed in 
    only one subcomponent of the system (e.g. a newer machine doesn’t 
    have just faster memory sticks, but also better CPU, chipset, 
    etc.).

The advent of cloud computing allows us to solve 1) using solutions 
like KVM [@kivity_kvm_2007] or software containers 
[@merkel_docker_2014]. ChameleonCloud [@mambretti_next_2015], CloudLab 
[@hibler_largescale_2008 ; @ricci_introducing_2014] and Grid5000 
[@bolze_grid5000_2006] are examples of bare-metal-as-a-service 
infrastructure available to researchers. DevOps 
[@wiggins_twelvefactor_2011 ; httermann_devops_2012] addresses 2). 
Thus, the main challenge with this approach lies in quantifying the 
performance of the platform in a consistent way. One alternative is to 
look at the hardware specification and infer performance 
characteristics from this. As has been shown **`[needs-citation]`**, 
this is not consistent. For example, the spec might specify that the 
machine has DDR4 memory sticks, with a theoretical peak throughput of 
10 GB/s, but the actual memory bandwidth could be less (usually is, by 
a non-deterministic fraction of the advertised performance).

_quiho_ solves this problem by characterizing machine performance 
using microbenchmarks (@Fig:perf-vectors). These performance vectors 
are the "fingerprint" that characterizes the behavior of a machine 
[@jimenez_characterizing_2016a].

![Performance vectors are obtained by executing a battery of 
microbenchmarks that quantify the performance of multiple 
subcomponents of a machine.
](figures/perf-vectors.png){#fig:perf-vectors}

This performance vectors, obtained over a sufficiently large set of 
machines[^how-big], can serve as the foundation for building a prediction 
model of the performance of an application when executed on new 
("unseen") machines [@boyse_straightforward_1975], a natural next step 
to take with a dataset like this. As we show in @Sec:negative, this is 
not as good as we would expect.

However, building a prediction model has a utility. If we use these 
performance vectors to apply SRA and we focus on feature importance 
[@kira_practical_1992] of the created models, we can see that they 
give us fine granularity resource utilization patterns. In 
@Fig:vectors-and-regression, we show the intuition behind why this is 
so. The performance of an application is determined by the performance 
of the subcomponents that get stressed the most by the application's 
code. Thus, intuitively, if the performance of an application across 
multiple machines resembles the performance of a microbenchmark, then 
we can say that the application is heavily influenced by that 
subcomponent.

[^how-big]: As mentioned in @Sec:conclusion, an open problem is to 
identify the minimal set of machines needed to obtaining meaningful 
results from SRA.

![Intuition behind why feature importance implies resource utilization 
behavior. The variability patterns for a feature (across multiple 
machines), resembles the same variability pattern of application 
performance across the same machines. While this can be inferred by 
obtaining correlation coefficients, proper SRA is needed in order to 
create prediction models, as well as to obtain a relative rank of 
feature importances.
](figures/featureimportance-implies-bottleneck.png){#fig:featureimportance-implies-bottleneck}

If we rank features by their relative importance, we obtain what we 
call a fine granularity resource utilization profile (FGRUP), as shown 
in @Fig:fgrusp.

![An example profile showing the relative importance of features for a 
particular application.
](figures/mariadb-memory.png){#fig:fgrup}

In the next section we show how these FGRUPs can be used in automated 
performance regression tests. @Sec:eval empirically validates this 
approach.

# Our Approach {#sec:quiho}

In this section we do an in-depth description of _quiho_'s approach. 
We first describe how we obtain the performance vectors that 
characterize system performance. We then show how using these vectors 
we can feed SRA to build performance models for an application. 
Lastly, we describe how we obtain feature importance and how this 
represent a fine granularity resource utilization profile (FGRUP). 

## Performance Feature Vectors As System Performance Characterization

While the hardware and software specification can serve to describe 
the performance characteristics of a machine, the real performance 
characteristics can only feasibly[^feasible] be obtained by executing 
programs and capturing metrics. **`[can we show data for this? or add 
citation]`** The question then boils down to which programs should we 
use to characterize performance? Ideally, we would like to have many 
programs that execute every possible opcode mix so that we measure 
their performance. Since this is an impractical solution, an 
alternative is to create synthetic microbenchmarks that get as close 
as possible to exercising all the available features of a system.

[^feasible]: One can get generate arbitrary performance 
characteristics by interposing a hardware emulation layer and 
deterministically associate performance characteristics to each 
instruction based on specific hardware specs. While possible, this is 
impractical (we are interested in characterizing "real" performance).

`stress-ng`[^stress-ng] is a tool that is used to "stress test a 
computer system in various selectable ways. It was designed to 
exercise various physical subsystems of a computer as well as the 
various operating system kernel interfaces". There are multiple 
stressors for CPU, CPU cache, memory, OS, network and filesystem. 
Since we focus on system performance bandwidth, we execute the (as of 
version 0.07.29) 42 stressors for CPU, memory and virtual virtual 
memory stressors. A _stressor_ is a function that loops a for a fixed 
amount of time (i.e. a microbenchmark), exercising a particular 
subcomponent of the system. At the end of its execution, `stress-ng` 
reports the rate of iterations executed for the specified period of 
time (referred to as `bogo-ops-per-second`).

[^stress-ng]: http://kernel.ubuntu.com/~cking/stress-ng

![List of different type of machines available on Cloudlab.
](figures/machines.png){#fig:machines}

Using this battery of stressors, we can obtain a performance profile 
of a machine (a performance vector). When this vector is compared 
against the one corresponding to another machine, we can quantify the 
difference in performance between the two at a per-stressor level. 
Every stressor (element in the vector) can be mapped to basic features of the 
underlying platform. For example, `stream` to memory bandwidth, `zero` 
to memory mapping, `qsort` to sorting data, and so on and so forth. 
However, the performance of a stressor in this set is _not_ completely 
orthogonal to the rest. @Fig:corrmatrix shows a heat-map of Pearson 
correlation coefficients for performance vectors obtained by executing 
`stress-ng` on all the distinct machine configurations available in 
CloudLab [@ricci_introducing_2014] (@Fig:machines shows a summary of 
their hardware specs). As the figure shows, some stressors are 
slightly correlated (those near 0) while others show high correlation 
between them (in @Sec:negative we apply principal component analysis 
to this dataset).

![heat-map of Pearson correlation coefficients for performance vectors 
obtained by executing `stress-ng` on all the distinct machine 
configurations available in CloudLab.
](figures/corrmatrix.png){#fig:corrmatrix}

## System Resource Utilization Via Feature Importance in SRA

SRA is an approach for modeling the relationship between variables, 
usually corresponding to observed data points 
[@freedman_statistical_2009]. One or more independent variables are 
used to obtain a _regression function_ that explains the values taken 
by a dependent variable. A common approach is to assume a _linear 
predictor function_ and estimate the unknown parameters of the modeled 
relationships.

A large number of procedures have been developed for parameter 
estimation and inference in linear regression. These methods differ in 
computational simplicity of algorithms, presence of a closed-form 
solution, robustness with respect to heavy-tailed distributions, and 
theoretical assumptions needed to validate desirable statistical 
properties such as consistency and asymptotic efficiency. Some of the 
more common estimation techniques for linear regression are 
least-squares, maximum-likelihood estimation, among others.

`sklearn` [@pedregosa_scikitlearn_2011] provides with many of the 
previously mentioned techniques for building regression models. 
Another technique available is gradient boosting 
[@prettenhofer_gradient_2014]. Gradient boosting is a machine learning 
technique for regression and classification problems, which produces a 
prediction model in the form of an ensemble of weak prediction models, 
typically decision trees [@friedman_greedy_2001]. It builds the model 
in a stage-wise fashion like other boosting methods do, and it 
generalizes them by allowing optimization of an arbitrary 
differentiable loss function. This function is then optimized over 
function space by iteratively choosing a function (weak hypothesis) 
that points in the negative gradient direction. @Fig:fgrup-generation 
shows the process applied to obtain FGRUPs for an application. In the 
next section we evaluate their effectiveness.

![The workflow applied in order to obtain FGRUPs.
](figures/fgrup-generation.png){#fig:fgrup-generation}


# Evaluation {#sec:eval}

In this section we answer:

  * can FGRUPs accurately capture application performance behavior?
  * can FGRUPs work for identifying simulated regressions?
  * can FGRUPs work for identifying real-world regressions?

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

![Variability.
](figures/variability.png){#fig:variability}

> "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![redis.
](figures/redis_get.png){#fig:redis-get}

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![redis lpop.
](figures/redis_lpop.png){#fig:redis-lpop}

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![sklearn
](figures/sklearn.png){#fig:sklearn}


## Simulating Regressions

We show that if we simulate regressions, then _quiho_ identifies them 
correctly.

![stream cycles
](figures/stream-cycles.png){#fig:stream-cycles}

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![stream copy-1
](figures/stream_copy-1.png){#fig:stream-copy1}

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![stream copy-20
](figures/stream_copy-20.png){#fig:stream-copy20}

text in between
"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![mariadb innodb.
](figures/mariadb_innodb.png){#fig:mariadb-innodb}

"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

![mariadb memory.
](figures/mariadb_memory.png){#fig:mariadb-memory}

Due to lack of space we can not include the remaining benchmarks. In 
total, we have 10 benchmarks for which we can induce several 
performance regressions, for a total of 30 performance regressions.

## Real-world Scenario

We show that _quiho_ works with a real software project.

![mariadb-5.5.58.
](figures/mariadb-5.5.58.png){#fig:mariadb-5.5.58}

![mariadb-10.0.3
](figures/mariadb-10.3.2.png){#fig:mariadb-10.0.32}

**Use of FGRUPs**: FGRUPs aid in performance engineering. When 
analyzing any performance degradation of an application, then the 
feature importance can be used as a pointer to where to start with the 
investigation. For example, if _memorymap_ ends up being the most 
important feature, then we can start by looking at any code/libraries 
related to this functionality, or looking at corresponding performance 
counters (if available). In this case, we would look for the code.

Due to lack of space, we cannot present results for 5 other 
applications where we detect regressions successfully. These are ZLog, 
Apache Commons Math, GCC, PostgresSQL, Redis, Apache Web Server and 
MongoDB.

[^popper-url]: http://falsifiable.us
[^gh]: http://github.com/ivotron/quiho-popper

## _quiho_ cannot predict performance {#sec:negative}

![Variability reduction per subcomponent in PCA.
](figures/pca-var-reduction.png){#fig:pca-var}

We show how _quiho_ does not do a good job at predicting performance.

![Variability reduction per index.
](figures/contribution-by-feature.png){#fig:feature-contrib}

text in between

![Mean Absolute Percentage Error of cross-validation.
](figures/prediction.png){#fig:prediction}

text in between

# Related Work {#sec:sra}


## Anomaly Detection and Bottleneck Identification

It's been used in bottleneck detection [@ibidunmoye_performance_2015]. 
**TODO: mention briefly how it is used**.

## Automated Regression Testing

In [@shang_automated_2015], they use it to detect regressions using a 
dataset of performance counters.

# Conclusion and Future Work {#sec:conclusion}

  * Main draw-back of this technique is that we need to run on 
    multiple machines.

  * We used `stress-ng` but this is not the only thing we can use. 
    Ideally, we would extend this battery of tests so that we have 
    more "coverage" of the distinct subcomponents of a system.

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

\noindent
\vspace{-1em}
\setlength{\parindent}{-0.175in}
\setlength{\leftskip}{0.2in}
\setlength{\parskip}{0.5pt}
\fontsize{7pt}{8pt}\selectfont
