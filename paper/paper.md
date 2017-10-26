---
title: "_quiho_: Automated Performance Regression Using Fine Granularity Resource Utilization Profiles"
shorttitle: _quiho_
author:
- name: Ivo Jimenez
  affiliation: UC Santa Cruz
  email: ivo.jimenez@ucsc.edu
- name: Noah Watkins
  affiliation: UC Santa Cruz
  email: nmwatkin@ucsc.edu
- name: Michael Sevilla
  affiliation: UC Santa Cruz
  email: msevilla@ucsc.edu
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
  application. It achieves this by applying sensitivity analysis, in 
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
keywords:
- software testing
- performance engineering
- performance modeling
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
occurred [@cherkasova_anomaly_2008]. Simply comparing values (e.g.,
runtime) is not enough, even if this is done in statistical terms 
(e.g., mean runtime within a pre-defined variability range). 
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
[@gregg_systems_2013]. Automated solutions have been proposed in 
recent years [@jiang_automated_2010 ; @shang_automated_2015 ; 
@heger_automated_2013]. The general approach of these is to analyze 
logs and/or metrics obtained as part of the execution of an 
application in order to automatically determine whether a regression 
has occurred. This relies on having accurate prediction models that 
are checked against runtime metrics of executed tests. As with any 
prediction model, there is the risk of false/positive negatives. 
Rather than striving for high accuracy predictions, an alternative is 
to use performance modeling as a profiling tool.

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

  * An automated end-to-end framework (based on the above finding), 
    that aids analysts in identifying significant changes in resource 
    utilization behavior of applications which can also aid in 
    identifying root cause of regressions.

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
in a performance metric of interest (e.g., runtime). At this point, an 
analyst will investigate further in order to find the root cause of the 
problem. One of these activities involves profiling an application to see 
the resource utilization pattern. Traditionally, 
coarse-grained profiling (i.e. CPU-, memory- or IO-bound) 
can be obtained by monitoring an application's resource utilization 
over time. Fine granularity behavior helps application developers and 
performance engineers quickly understand what they need to focus on 
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

 1. Consistent Software. We need to ensure that the software stack is 
    the same on all machines where the application runs.
 2. Application Testing Overhead. The amount of effort required to run 
    applications on a multitude of platforms is not negligible.
 3. Hardware Performance Characterization. It is difficult to obtain 
    the performance characteristics of a machine by just looking at 
    the hardware spec, so other more practical alternative is 
    required.
 4. Correlating Performance. Even if we could solve the above issue 
    (Hardware Performance Characterization) and infer performance 
    characteristics by just looking at the hardware specification of a 
    machine, there is still the problem of not being able to correlate 
    baseline performance with application behavior, since between two 
    platforms is rarely the case where the change of performance is 
    observed in only one subcomponent of the system (e.g., a newer 
    machine doesn’t have just faster memory sticks, but also better 
    CPU, chipset, etc.).

The advent of cloud computing allows us to solve 1 using solutions 
like KVM [@kivity_kvm_2007] or software containers 
[@merkel_docker_2014]. ChameleonCloud [@mambretti_next_2015], CloudLab 
[@hibler_largescale_2008 ; @ricci_introducing_2014] and Grid5000 
[@bolze_grid5000_2006] are examples of bare-metal-as-a-service 
infrastructure available to researchers that can be used to automate 
regression testing pipelines for the purposes of investigating new 
approaches. These solutions to infrastructure automation coupled with 
DevOps practices [@wiggins_twelvefactor_2011 ; httermann_devops_2012] 
allows us to address 2, i.e. to reduce the amount of work required to 
run tests.

Thus, the main challenge to inferring fine granularity resource 
utilization patterns (3 and 4) lies in quantifying the performance of 
the platform in a consistent way. One alternative is to look at the 
hardware specification and infer performance characteristics from 
this, an almost impossible task. For example, the 
spec might specify that the machine has DDR4 memory sticks, with a 
theoretical peak throughput of 10 GB/s, but the actual memory 
bandwidth could be less (usually is, by a non-deterministic fraction 
of the advertised performance). _quiho_ solves this problem by 
characterizing machine performance using microbenchmarks. These 
performance vectors are the "fingerprint" that characterizes the 
behavior of a machine [@jimenez_characterizing_2016a].

These performance vectors, obtained over a sufficiently large set of 
machines[^how-big], can serve as the foundation for building a 
prediction model of the performance of an application when executed on 
new ("unseen") machines [@boyse_straightforward_1975], a natural next 
step to take with a dataset like this. As we show in @Sec:negative, 
this is not as good as we would expect.

However, building a prediction model has a utility. If we use these 
performance vectors to apply SRA and we focus on feature importance 
[@kira_practical_1992] of the created models, we can see that they 
give us fine granularity resource utilization patterns. In 
@Fig:featureimportance-implies-bottleneck, we show the intuition 
behind why this is so. The performance of an application is determined 
by the performance of the subcomponents that get stressed the most by 
the application's code. Thus, intuitively, if the performance of an 
application across multiple machines resembles the performance of a 
microbenchmark, then we can say that the application is heavily 
influenced by that subcomponent.

[^how-big]: As mentioned in @Sec:conclusion, an open problem is to 
identify the minimal set of machines needed to obtaining meaningful 
results from SRA.

![Intuition behind why feature importance implies resource 
utilization behavior. The variability patterns for a feature (across 
multiple machines), resembles the same variability pattern of 
application performance across the same machines. While this can be 
inferred by obtaining correlation coefficients, proper SRA is needed 
in order to create prediction models, as well as to obtain a relative 
rank of feature importances.
](figures/featureimportance-implies-bottleneck.png){#fig:featureimportance-implies-bottleneck}

If we rank features by their relative importance, we obtain what we 
call a fine granularity resource utilization profile (FGRUP), as shown 
in @Fig:fgrup.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-hpccg-redis-sklearn-ssca.ipynb)\] 
An example profile showing the relative importance of features for a 
particular application.
](figures/hpccg.png){#fig:fgrup}

In the next section we show how these FGRUPs can be used in automated 
performance regression tests. @Sec:eval empirically validates this 
approach.

# Our Approach {#sec:quiho}

In this section we do describe _quiho_'s approach and the resulting prototype.
We first describe how we obtain the performance vectors that 
characterize system performance. We then show that  
we can feed these vectors into  SRA to build performance models for an application. 
Lastly, we describe how we obtain feature importance and how this 
represents a fine granularity resource utilization profile (FGRUP). 

## Performance Feature Vectors As System Performance Characterization

While the hardware and software specification can serve to describe 
the performance characteristics of a machine, the real performance 
characteristics can only feasibly be obtained by executing programs 
and capturing metrics. One can get generate arbitrary performance 
characteristics by interposing a hardware emulation layer and 
deterministically associate performance characteristics to each 
instruction based on specific hardware specs. While possible, this is 
impractical (we are interested in characterizing "real" performance). 
The question then boils down to which programs should we use to 
characterize performance? Ideally, we would like to have many programs 
that execute every possible opcode mix so that we measure their 
performance. Since this is an impractical solution, an alternative is 
to create synthetic microbenchmarks that get as close as possible to 
exercising all the available features of a system.

\begin{table}\caption{\label{tbl:stressng-categories} List of stressors used in this paper and how they are categorized by `stress-ng`. Note that some stressors are part of multiple categories.}
\footnotesize
\input{figures/stressng-categories.tex}
\end{table}

`stress-ng`[@king_stressng_2017] is a tool that is used to "stress 
test a computer system in various selectable ways. It was designed to 
exercise various physical subsystems of a computer as well as the 
various operating system kernel interfaces". There are multiple 
stressors for CPU, CPU cache, memory, OS, network and filesystem. 
Since we focus on system performance bandwidth, we execute the (as of 
version 0.07.29) 42 stressors for CPU, memory and virtual virtual 
memory stressors (@Tbl:stressng-categories shows the list of stressors 
used in this paper). A _stressor_ is a function that loops a for a 
fixed amount of time (i.e. a microbenchmark), exercising a particular 
subcomponent of the system. At the end of its execution, `stress-ng` 
reports the rate of iterations executed for the specified period of 
time (referred to as `bogo-ops-per-second`).

\begin{table}\caption{\label{tbl:machines} Table of machines from 
CloudLab. The last three entries correspond to computers from our 
lab.}
\footnotesize
\input{figures/machines.tex}
\end{table}

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize.ipynb)\] 
Boxplots illustrating the variability of the performance vector 
dataset. Each stressor was executed on each of the machines listed in 
@Tab:machines 5 times.
](figures/stressng-variability.png){#fig:stressng-variability}

Using this battery of stressors, we can obtain a performance profile 
of a machine (a performance vector). When this vector is compared 
against the one corresponding to another machine, we can quantify the 
difference in performance between the two at a per-stressor level. 
@Fig:stressng-variability shows the variability in these performance 
vectors.

Every stressor (element in the vector) can be mapped to basic features 
of the underlying platform. For example, `bigheap` is directly 
associated to memory bandwidth, `zero` to memory mapping, `qsort` to 
CPU performance (in particular to sorting data), and so on and so 
forth. However, the performance of a stressor in this set is _not_ 
completely orthogonal to the rest, as implied by the overlapping 
categories in @Tbl:stressng-categories. @Fig:corrmatrix shows a 
heat-map of Pearson correlation coefficients for performance vectors 
obtained by executing `stress-ng` on all the distinct machine 
configurations available in CloudLab [@ricci_introducing_2014] 
(@Tbl:machines shows a summary of their hardware specs). As the figure 
shows, some stressors are slightly correlated (those near 0) while 
others show high correlation between them (in @Sec:negative we apply 
principal component analysis to this dataset).

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize.ipynb)\] 
heat-map of Pearson correlation coefficients for performance vectors 
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

`scikit-learn` [@pedregosa_scikitlearn_2011] provides with many of the 
previously mentioned techniques for building regression models. 
Another technique available in `scikit-learn` is gradient boosting 
[@prettenhofer_gradient_2014]. Gradient boosting is a machine learning 
technique for regression and classification problems, which produces a 
prediction model in the form of an ensemble of weak prediction models, 
typically decision trees [@friedman_greedy_2001]. It builds the model 
in a stage-wise fashion like other boosting methods do, and it 
generalizes them by allowing optimization of an arbitrary 
differentiable loss function. This function is then optimized over a 
function space by iteratively choosing a function (weak hypothesis) 
that points in the negative gradient direction.

Once an ensemble of trees for an application is generated, feature 
importances are obtained in order to use them as the FGRUP for an 
application. @Fig:fgrup-generation shows the process applied to 
obtaining FGRUPs for an application. `scikit-learn` implements the 
feature importance calculation algorithm introduced in 
[@breiman_classification_1984]. This is sometimes called _gini 
importance_ or _mean decrease impurity_ and is defined as the total 
decrease in node impurity, weighted by the probability of reaching 
that node (which is approximated by the proportion of samples reaching 
that node), averaged over all trees of the ensemble.

We note that before generating a regression model, we normalize the 
data using the `StandardScaler` method from `scikit-learn`, which 
removes the mean from the dataset and scales the data to unit 
variance. Given that the `bogo-ops-per-second` metric does not 
quantify work consistently across stressors, we normalize the data in 
order to prevent some features from dominating in the process of 
creating the prediction models. In section @Sec:eval we evaluate the 
effectiveness of FGRUPs.

![The workflow applied in order to obtain FGRUPs.
](figures/fgrup-generation.png){#fig:fgrup-generation}

## Using FGRUPs in Automated Regression Tests {#sec:compare-fgrups}

As shown in @Fig:pipeline (step 4), when trying to determine whether a 
performance degradation occurred, FGRUPs can be used to compare 
differences between current and past versions of an application. In 
order to do so, we apply a simple algorithm. Given two profiles $A$ 
and $B$, and an arbitrary $\epsilon$ value, look at first feature in 
the ranking (highest in the chart). Then, compare the relative 
importance value for the feature and importance values for $A$ and 
$B$. If relative importance is not within $+/-\epsilon$, the 
importance is considered not equivalent and the algorithm stops. If 
values are similar (within $+/-\epsilon$), we move to the next, less 
important factor and the compare again. This is repeated for as many 
features are present in the dataset.

FGRUPs can also be used as a pointer to where to start with an 
investigation that looks for the root cause of the regression 
(@Fig:pipeline, step 5). For example, if _memorymap_ ends up being the 
most important feature, then we can start by looking at any 
code/libraries that make use of this subcomponent of the system. An 
analyst could also trace an application using performance counters and 
look at corresponding performance counters to see which code paths 
make heavy use of the subcomponent in question.

# Evaluation {#sec:eval}

In this section we answer four main questions:

 1. Can FGRUPs accurately capture application performance behavior? 
    (@Sec:effective-fgrups)
 2. Can FGRUPs work for identifying simulated regressions? 
    (@Sec:fgrups-for-simulated)
 3. Can FGRUPs work for identifying regressions in real world software 
    projects? (@Sec:fgrups-for-real)
 4. Can performance vectors be used to create performance prediction 
    models? (@Sec:negative)

**Note on Replicability of Results**: This paper adheres to The Popper 
Experimentation Protocol and convention[^popper-url] 
[@jimenez_popper_2017], so experiments presented here are available in 
the repository for this article[^gh]. We note that rather than 
including all the results in the paper, we instead include 
representative ones for each section and leave the rest on the paper 
repository. Experiments can be examined in more detail, or even 
re-executed, by visiting the `[source]` link next to each figure. That 
link points to a Jupyter notebook that shows the analysis and source 
code for that graph. The parent folder of the notebook (following the 
Popper's file organization convention) contains all the artifacts and 
automation scripts for the experiments. All results presented here can 
be replicated[^acm-badges], as long as the reader has an account at 
Cloudlab (see repo for more details).

[^acm-badges]: **Note to reviewers**: based on the terminology 
described in the ACM Badging Policy [@acm_result_2016] this complies 
with the _Results Replicable_ category. We plan to submit this work to 
the artifact review track too.

## Effectiveness of FGRUPs to capture performance {#sec:effective-fgrups}

In this subsection we show how FGRUPs can effectively describe the 
fine granularity resource utilization of an application with respect 
to a set of machines. Our methodology is:

  1. Discover relevant performance features using the _quiho_ 
     framework.
  2. Analyze source code to corroborate that discovered features are 
     indeed the cause of performance differences.

We execute multiple applications for which fine granularity resource 
utilization characteristics we know in advance. These applications are 
redis [@zawodny_redis_2009], scikit-learn 
[@pedregosa_scikitlearn_2011], and ssca [@bader_design_2005] and 
others. As a way to illustrate the variability originating from 
executing these applications on an heterogeneous set of machines, 
@Fig:variability shows boxplots of the four redis performance tests we 
execute.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-hpccg-redis-sklearn-ssca.ipynb)\] 
Variability in the redis benchmarks. Y-axis is transactions per 
second.
](figures/variability.png){#fig:variability}

In @Fig:redis we show four profiles side-by-side of four operations on 
redis, a popular open-source in-memory key-value database. These four 
tests are `PUT`, `GET`, `LPOP` and `LPUSH`. These benchmarks that test 
operations that put and get key-value pairs into the DB, and push/pop 
elements from a list stored in a key, respectively. The resource 
utilization profiles suggest that `GET` and `PUT` are memory intensive 
operations (first 3 stressors from each test, as shown in 
@Tbl:stressng-categories). On the other hand, the profiles for `LPOP` 
and `LPUSH` look different and they seem to have CPU intensive as the 
most important feature for this. If we look at the source code of 
redis, we can see why this is so. In the case of `GET` and `PUT`, 
these are memory intensive tasks. In the case of `LPOP` and `LPUSH`, 
these are routines that retrieve/replace the first element in the 
list, which is cpu-intensive and correlate with cpu-intensive 
stressors (such as `hsort` and `qsort`).

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-hpccg-redis-sklearn-ssca.ipynb)\] 
FGRUPs for four redis tests (`PUT`, `GET`, `LPOP` and `LPUSH`). These 
benchmarks that test operations that put and get key-value pairs into 
the DB, and push/pop elements from a list stored in a key, 
respectively.
](figures/redis.png){#fig:redis}

@Fig:sklearn-ssca shows the profile for one of the sklearn 
classification algorithm performance test. `scikit-learn` uses NumPy 
[@walt_numpy_2011] internally, which is known to be memory-bound. SSCA 
on the other hand known to be CPU-bound.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-hpccg-redis-sklearn-ssca.ipynb)\] 
Profiles for the applications scikitlearn and ssca.
](figures/sklearn-ssca.png){#fig:sklearn-ssca}

[^brevity]: For brevity, we omit other results that corroborate FGRUPs 
can correctly identify patterns. All these are available in the github 
repository associated to this article.

## Simulating Regressions {#sec:fgrups-for-simulated}

In this section we test the effectiveness of _quiho_ to detect 
performance simulations that are artificially induced. We induce 
regression by having a set of performance tests that take, as input, 
parameters that determine their performance behavior, thus simulating 
different "versions" of the same application. In total, we have 10 
benchmarks for which we can induce several performance regressions, 
for a total of 30 performance regressions. For brevity, in this 
section we present results for two applications, MariaDB 
[@widenius_mariadb_2009] and the STREAM-cycles.

The MariaDB test is based on the `mysqlslap` utility for stressing the 
database. In our case we run the load test, which populates a database 
whose schema is specified by the user. In our case, we have a fixed 
set of parameters that load a 10GB database. One of the exposed 
parameters is the one that selects the backend (storage engine in 
MySQL terminology). While the workload and test parameters are the 
same, the code paths are distinct and thus present different 
performance characteristics. The two engines we use in this case are 
`innodb` and `memory`. @Fig:mariadb-innodb-vs-memory shows the 
profiles of MariaDB performance for these two engines.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize.ipynb)\] 
MariaDB with innodb and in-memory backends.
](figures/mariadb-innodb-vs-memory.png){#fig:mariadb-innodb-vs-memory}

The next test is a modified version of the STREAM benchmark, which we 
refer to as STREAM-cycles. This version of STREAM introduces a 
`cycles` parameter that controls the number of times a STREAM 
operation is executed before reporting the time it took. In terms of 
the code, this adds an outer loop to each of the four different STREAM 
operations (`add`, `triad`, `copy`, `scale`), and loops as many times 
as the `cycles` parameter specifies. All STREAM tests are memory 
bound, so adding more cycles move the performance test from memory- to 
being cpu-bound; the higher the value of the `cycles` parameter, the 
more cpu-bound the test gets. @Fig:stream-cycles shows this behavior 
of all four tests across many machines.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize.ipynb)\] 
General behavior of the STREAM-cycles performance test. All STREAM 
tests are memory bound, so adding more cycles move the performance 
test from memory- to being cpu-bound; the higher the value of the 
`cycles` parameter, the more cpu-bound the test gets.
](figures/stream-cycles.png){#fig:stream-cycles}

@Fig:stream-fgrups shows the FGRUPs for the four tests. On the left, 
we see the "normal" resource utilization behavior of the "vanilla" 
version of STREAM (which corresponds to a value of 1 for the `cycles` 
parameter). As expected, the associated features (stressors) to these 
are from the memory/VM category. To the right, we see FGRUPs capturing 
the change in utilization behavior when `cycles` goes to its maximum 
value (20). In general FGRUPs do a good job of catching the simulated 
regression (which causes this application to be cpu-bound instead of 
memory-bound).

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize.ipynb)\] 
The FGRUPs for the four tests. We see that they capture the simulated 
regression (which causes this application to be cpu-bound instead of 
memory-bound).
](figures/stream-fgrups.png){#fig:stream-fgrups}

## Real world Scenario {#sec:fgrups-for-real}

In this section we show that _quiho_ works with regressions that can 
be found in real software projects. It is documented that the changes 
made to the `innodb` storage engine in version 10.3.2 improves the 
performance in MariaDB, with respect to previous version 5.5.58. If we 
take the development timeline and invert it, we can treat 5.5.58 as if 
it was a "new" revision that introduces a performance regression. To 
show that this can be captured with FGRUPs, we use `mysqlslap` again 
and run the `load` test. @Fig:mariadb-innodb-regression shows the 
corresponding FGRUPs. We can observe that the FGRUP generated by 
_quiho_ can identify the difference in performance.

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-mysql-two-versions.ipynb)\] 
A regression that appears from going in the reversed timeline (from 
mariadb-10.0.3 to 5.5.38).
](figures/mariadb-innodb-regression.png){#fig:mariadb-innodb-regression}

For brevity, we omit regressions found in other 4 applications (zlog, 
postgres, redis, apache web server and GCC).

[^popper-url]: http://falsifiable.us
[^gh]: http://github.com/ivotron/quiho-popper

## Using Performance Vectors to Predict Performance {#sec:negative}

As mentioned earlier, the set of performance vectors obtained as part 
of the generation of FGRUPs could be used to create prediction models 
that try to estimate the performance of an application using. 
@Fig:prediction shows a plot with mean absolute percentage errors 
(MAPE) corresponding to the outcome of doing 1-cross-validation 
[@kohavi_study_1995] across the distinct type of hardware 
architectures found in CloudLab. The 1-cross-validation is done by 
creating a training dataset composed of performance vectors from all 
but one machine. We then generate the model using this training subset 
as the independent variables and the performance metric associated to 
an application performance as the dependant variable. We then test 
obtain the accuracy of the model on the data corresponding to the 
machine that we left out. Before

![\[[source](https://github.com/ivotron/quiho-popper/tree/icpe18-submission/experiments/single-node/results/visualize-predict.ipynb)\] 
Mean Absolute Percentage Error of cross-validation.
](figures/prediction.png){#fig:prediction}

We create two prediction models. The first one is using random forest 
[@liaw_classification_2002] to create a linear regression performance 
model (blue line). We select random forest (as opposed to selecting other 
alternatives), since it is the one with the highest estimation 
accuracy from all the ones we tried. As mentioned previously, data is 
first normalized to prevent dimensionality issues. The second model is 
obtained by creating a pipeline, where principal component analysis 
(PCA) is applied first and then random forest is applied next (green 
line). As we can see, the prediction errors range from 3% up to almost 
50% in the worst-case scenario. Compared to the status-quo 
[@crume_automatic_2014], where good performance prediction models are 
those with less than 2-3% MAPE.

# Related Work {#sec:sra}

## Automated Regression Testing

Automated regression testing can be broken down in the following three 
steps:

  1. In the case of large software projects, decide which tests to 
     execute [@kazmi_effective_2017]. This line of work is 
     complementary to _quiho_.
  2. Once a test executes, decide whether a regression has occurred 
     [@syer_continuous_2014]. This can be broken down in mainly two 
     categories, as explained in [@shang_automated_2015]: pair-wise 
     comparisons and model assisted. _quiho_ fits in the latter 
     category, the main difference being that, as opposed to existing 
     solutions, _quiho_ does not rely on having accurate prediction 
     models since its goal is to describe resource utilization (obtain 
     FGRUPs).
  3. If a regression is observed, automatically find the root cause or 
     aid an analyst to find it [@ibidunmoye_performance_2015 ; 
     @heger_automated_2013 ; @attariyan_xray_2012]. While _quiho_ does 
     not find the root cause of regressions, it complements the 
     information that an analyst has available to investigate further.

## Decision Trees

In [@jung_detecting_2006] the authors use decision trees to detect 
anomalies and predict performance SLO violations. They validate their 
approach using a TPC-W workload in a multi-tiered setting. In 
[@shang_automated_2015], the authors use performance counters to build 
a regression model aimed at filtering out irrelevant performance 
counters. In [@nguyen_automated_2012a], the approach is similar but 
statistical process control techniques are employed instead.

In the case of _quiho_, the goal is to use decision trees as a way of 
obtaining feature performance, thus, as opposed to what it's proposed 
in [@shang_automated_2015], the leaves of the generated decision trees 
contain actual performance predictions instead of the name of 
performance counters

## Correlation-based and Supervised Learning

Correlation-based and supervised learning approaches have been 
proposed in the context of software testing, mainly for detecting 
anomalies [@ibidunmoye_performance_2015]. In the former, runtime 
performance metrics are correlated to application performance using a 
variety of distinct techniques. In supervised learning, the goal is 
the same (build prediction models) but using a labeled dataset.

Given that _quiho_ is not using classification techniques, it doesn't 
rely on labeled datasets. Also, and as explained in @Sec:quiho, this 
type of analysis does not serve our needs, since we need to obtain a 
prediction model in order to look at feature importance (the basis of 
FGRUPs). Lastly, _quiho_ is not intended to be used as a way of 
detecting anomalies, although we have not analyzed its potential use 
in this scenario.

# Limitations and Future Work {#sec:conclusion}

The main limitation in _quiho_ is the requirement of having to execute 
a test on more than one machine in order to obtain FGRUPs. As 
mentioned, an open problem is to precisely quantify the minimum amount 
of required machines. Time can be saved by carefully avoiding to 
re-execute `stress-ng` every time a test is executed, for example by 
keeping track of workload placement in a cluster of machines.

We used `stress-ng` but the approach is not limited to this 
benchmarking toolkit. Ideally, we would like to extend the amount and 
type of stressors so that we have more coverage over the distinct 
subcomponents of a system. An open question is to systematically test 
whether the current set of stressors is sufficient to cover all 
subcomponents of a processor.

We are currently working in adapting this approach to profile 
distributed and multi-tiered applications. We also plan to analyze the 
viability of using _quiho_ in multi-tenant configurations. Lastly, 
long-running (multi-stage) applications. e.g., a web-service or 
big-data application with multiple stages. In this case, we would 
define windows of time and we would apply quiho to each. The 
challenge: how do we automatically get the windows rightly placed.

In the era of cloud computing, even the most basic computer systems 
are complex multi-layered pieces of software, whose performance 
properties are difficult to comprehend. Having complete understanding 
of the performance behavior of an application, considering the 
parameter space (workloads, multitenancy, etc.) is very challenging. 
One application of _quiho_ we have in mind is to couple it with 
automated black-box (or even gray-box) testing frameworks to improve 
our understanding of complex systems.

**Acknowledgments**: This work was partially funded by the Center for 
Research in Open Source Software[^cross], Sandia National Laboratories 
and NSF Award #1450488.

[^cross]: http://cross.ucsc.edu


# References {.unnumbered}

\noindent
\vspace{-1em}
\setlength{\parindent}{-0.175in}
\setlength{\leftskip}{0.2in}
\setlength{\parskip}{0.5pt}
\fontsize{7pt}{8pt}\selectfont
