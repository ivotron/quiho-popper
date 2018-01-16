---
title: "_quiho_: Automated Performance Regression Testing Using Inferred Resource Utilization Profiles"
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
  We introduce _quiho_, a framework for profiling application 
  performance that can be used in automated performance regression 
  tests. _quiho_ profiles an application by applying sensitivity 
  analysis, in particular statistical regression analysis (SRA), using 
  application-independent performance feature vectors that 
  characterize the performance of machines. The result of the SRA, 
  feature importance specifically, is used as a proxy to identify 
  hardware and low-level system software behavior. The relative 
  importance of these features serve as a performance profile of an 
  application (termed inferred resource utilization profile or 
  IRUP), which is used to automatically validate performance behavior 
  across multiple revisions of an application's code base without having to instrument code or obtain performance counters. We 
  demonstrate that _quiho_ can successfully discover performance 
  regressions by showing its effectiveness in profiling application 
  performance for synthetically introduced regressions as well as those 
  found in real-world applications.
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
latency, or resource utilization over time. These metrics are captured 
and compared for multiple versions of an application (usually current 
and past versions) and, if significant differences are found, this 
constitutes a regression.

![_quiho_'s workflow for generating inferred resource utilization profiles (IRUPs) for an application. An IRUP is used as an alternative for 
profiling application performance and can complement automated 
regression testing. For example, after a change in the runtime of an application has been detected across two revisions of the code base, an IRUP can be obtained in order to determine whether this change is significant. IRUPs can also aid in root cause analysis.
](figures/irup-generation.png){#fig:irup-generation}

One of the main challenges in automating performance regression tests 
is defining the criteria to decide whether a change in 
application performance behavior is significant 
[@cherkasova_anomaly_2008]. Understanding the effects in performance 
that distinct hardware and low-level system software[^system] 
components have on applications demands highly-skilled performance 
engineering [@jin_understanding_2012 ; @han_performance_2012 ; 
@jovic_catch_2011]. Traditionally, this investigation is done by an 
analyst in charge of looking at changes to the performance metrics 
captured at runtime, possibly investigating deeply by looking at 
performance counters, performance profiles, static code analysis, and 
static/dynamic tracing. One common approach is to find bottlenecks by 
generating a profile (e.g., using the `perf` Linux kernel tool) in 
order to understand which parts of the system an application is 
hammering on [@gregg_systems_2013]. Profiling involves recording resource utilization for 
an application over time making use of tools such as `perf`. In 
general, this can be done in two ways: timed- and event-based 
profiles. Timed-based profiling samples the instruction pointer at 
regular intervals and generates a function call tree with each node in 
the three having a percentage of time associated with it, which 
represents the amount of time that the CPU spends within that piece of 
code. Event-based profiling samples at regular intervals different 
events at the hardware and OS level in order to obtain a distribution 
of events over the time that an application runs. In either case, the 
system needs to execute the application in a "profiling" mode, in 
order to have the OS enable the instrumentation mechanisms that has 
available to carry out this task.

Automated solutions have been proposed in recent years 
[@jiang_automated_2010 ; @shang_automated_2015 ; 
@heger_automated_2013]. The general approach of these is to analyze 
runtime logs and/or metrics 
application in order to build a performance prediction model that can 
be used to automatically determine whether a regression has occurred. 
This relies on having accurate predictions and, as with any prediction 
model, there is the risk of finding false negatives/positives. In addition to
striving for highly accurate predictions, one can also use performance 
modeling as a profiling tool.

In this work, we present _quiho_ an approach aimed at complementing 
automated performance regression testing by using inferred 
resource utilization profiles (IRUP) associated to an application. 
_quiho_ is 
an alternative framework for profiling an application where the utilization 
of one or more subsystems (e.g. virtual memory) is inferred by 
applying Statistical Regression Analysis[^sra] (SRA) on 
a dataset of application-independent performance vectors. 
The main 
assumption behind _quiho_ is the availability of multiple machines 
when exercising performance regression testing, a reasonable 
requirement that is well-aligned with current software engineering 
practices (performance regression is carried out on multiple 
architectures and OSs).

When an application is profiled using _quiho_ (@Fig:irup-generation, the machines available to the performance tests are 
baselined by executing a battery of microbenchmarks on each. This matrix 
of performance vectors characterizes the available machines 
independently from any application and can be used (and re-used) as 
the foundation for applying statistical learning techniques such as 
SRA. In order to infer resource utilization, the application under study is 
executed on the same machines from where the performance vectors where 
obtained, and SRA is applied. The result of the SRA for an 
application, in particular feature importance, is used as a proxy to 
characterize hardware and low-level system utilization behavior. The 
relative importance of these features constitutes what we refer to as 
an _inferred resource utilization profile_ (IRUP). @Fig:hpccg-irup 
shows an example of an IRUP for an application. Each feature in this 
relative ranking corresponds to a microbenchmark for a subcomponent of 
a system (e.g. floating point unit, virtual memory, etc.). Thus, this 
profile captures the resource utilization pattern of an application 
which can be used to automatically validate its performance behavior 
across multiple revisions of its code base, making _quiho_ an approach 
to characterizing applications that is resilient to code refactoring.

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
    identifying root cause of regressions, and that is resilient an 
    application code refactoring.

  * Methodology for evaluating automated performance regression. We 
    introduce a set of synthetic benchmarks aimed at evaluating 
    automated regression testing without the need of real bug 
    repositories. These benchmarks take as input parameters that 
    determine their performance behavior, thus simulating different 
    "versions" of an application.

Next section (@Sec:intuition) shows the intuition behind _quiho_ and 
how can be used to automate regression tests. We then do a more 
in-depth description of _quiho_ (@Sec:quiho), followed by our 
evaluation of this approach (@Sec:eval). We then 
discuss different aspects of our work (@Sec:discussion), review 
(@Sec:sra) related work and we lastly close with a brief discussion on 
challenges and opportunities enabled by _quiho_ (@Sec:conclusion).

[^system]: Throughout this paper, we use "system" to refer to the 
low-level compute stack composed by hardware, firmware and the 
operating system (OS).
[^name]: The word _quiho_ means "to discover" or "to find" in Seri, 
the dialect of a native tribe of the same name from Northwestern 
Mexico.
[^sra]: We use the term _Statistical Regression Analysis_ (SRA) to 
differentiate between regression testing in software engineering and 
regression analysis in statistics.

# Motivation and Intuition Behind _quiho_ {#sec:intuition}

![Automated regression testing pipeline integrating inferred resource 
utilization profiles (IRUP). IRUPs are obtained by _quiho_ and can be 
used both, for identifying regressions, and to aid in the quest for 
finding the root cause of a regression.
](figures/pipeline.png){#fig:pipeline}

@Fig:pipeline shows the workflow of an automated regression testing 
pipeline and shows how _quiho_ fits in this picture. A regression is 
usually the result of observing a significant change in a performance 
metric of interest (e.g., runtime). At this point, an analyst will 
investigate further in order to find the root cause of the problem. 
One of these activities involves profiling an application to see the 
resource utilization pattern. Traditionally, coarse-grained profiling 
(i.e. CPU-, memory- or IO-bound) can be obtained by monitoring an 
application's resource utilization over time. Fine granularity 
behavior helps application developers and performance engineers 
quickly understand what they need to focus on while refactoring an 
application.

Fine granularity performance utilization behavior can better inform 
the regression testing pipeline. Examples of which resources are 
included in this type of profiling are the OS memory mapping 
subsystem, the CPU's cryptographic unit, or the CPU cache. This type 
of profiling is time-consuming and requires use of more computing 
resources. This is usually done offline by analysts and involves 
eyeballing source code, static code analysis, or analyzing hardware/OS 
performance counters/profiles.

An alternative is to infer resource utilization behavior by comparing 
the performance of an application on platforms with different 
performance characteristics. For example, if we know that machine A 
has higher memory bandwidth than machine B, and an application is 
memory-bound, then this application will perform better on machine A. 
There are several challenges with this approach:

![A matrix of performance feature vectors over a colection of CloudLab 
servers (left), and an array of a performance metric for an 
application on those same machines (right). Every column in the matrix 
comes from executing a microbenchmark on that machine. This dataset of 
microbenchmarks allows us to create a performance prediction model for 
application. Variability patterns of an application (zlog in the 
example), resemble the same variability pattern of one or more 
performance microbenchmark(s). Thus, the system subcomponent exercised 
by the microbenchmark is likely to be also the cause of why the 
application exhibits such performance behavior.
](figures/featureimportance-implies-bottleneck.png){#fig:featureimportance-implies-bottleneck}

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

![An example profile showing the relative importance of features for an 
execution of the `hpccg` miniapp [@heroux_hpccg_2007]. The y-axis 
denotes the relative performance with respect to the most importante 
feature, which corresponds to the first one on the x-axis (from top to 
bottom).
](pipelines/single-node/results/figures/hpccg.png){#fig:hpccg-irup}

The advent of cloud computing allows us to solve (1) using solutions 
like KVM [@kivity_kvm_2007] or software containers 
[@merkel_docker_2014]. ChameleonCloud [@mambretti_next_2015], CloudLab 
[@hibler_largescale_2008 ; @ricci_introducing_2014] and Grid5000 
[@bolze_grid5000_2006] are examples of bare-metal-as-a-service 
infrastructure available to researchers that can be used to automate 
regression testing pipelines for the purposes of investigating new 
approaches. These solutions to infrastructure automation coupled with 
DevOps practices [@wiggins_twelvefactor_2011 ; @httermann_devops_2012] 
allows us to address (2), i.e. to reduce the amount of work required to 
run tests.

Thus, the main challenge to inferring resource utilization patterns 
lies in quantifying the performance of the platform in a consistent 
way (3,4). One alternative is to look at the hardware specification 
and infer performance characteristics from this, a highly inaccurate 
task due to the lack of correspondence between advertised (or theoretical peak throughput) and actual performance observed in reality. For example, the spec of a platform might specify that the machine has DDR4 
memory sticks, with a theoretical peak throughput of 10 GB/s, but the 
actual memory bandwidth could be less (usually is, by a 
non-deterministic fraction of the advertised performance).

_quiho_ solves this problem by characterizing machine performance 
using microbenchmarks. These performance vectors are the "fingerprint" 
that characterizes the behavior of a machine 
[@jimenez_characterizing_2016a]. These vectors, obtained 
over a sufficiently large set of machines[^how-big], can serve as the 
foundation for building a prediction model of the performance of an 
application when executed on new ("unseen") machines 
[@boyse_straightforward_1975]. Thus, a natural next step to take with 
a dataset like this is to try to build a prediction model.

While building a prediction model is obviously something that can be 
used to estimate the performance of an application, building one can 
also serve as a way of identifying resource utilization. If we use 
these performance vectors to apply SRA and we focus on feature 
importance [@kira_practical_1992] of the generated models, we can see 
that they allow us to infer resource utilization patterns. In 
@Fig:featureimportance-implies-bottleneck, we show the intuition 
behind why this is so. The performance of an application is determined 
by the performance of the subcomponents that get stressed the most by 
the application's code. Thus, intuitively, if the performance of an 
application across multiple machines resembles the performance of a 
microbenchmark, then we can say that the application is heavily 
influenced by that subcomponent. In other words, if the variability 
pattern of a feature across multiple machines resembles the 
variability pattern of application performance across those same 
machines, it is likely due to the application stressing the same 
subcomponent that the corresponding microbenchmark stresses. While 
this can be inferred by obtaining correlation coefficients, proper SRA 
is needed in order to create prediction models, as well as to obtain a 
relative rank of feature importances.

[^how-big]: In @Sec:discussion we briefly sketch how we would apply 
PAC to find the minimal set of machines needed to obtaining meaningful 
results from SRA.

If we rank features by their relative importance, we obtain what we 
call an inferred resource utilization profile (IRUP), as shown in 
@Fig:hpccg-irup. In the next section we show how these IRUPs can be 
used in automated performance regression tests. @Sec:eval empirically 
validates this approach.

# Our Approach {#sec:quiho}

In this section we describe _quiho_'s approach and the resulting 
prototype. We first describe how we obtain the performance vectors 
that characterize system performance. We then show that we can feed 
these vectors to SRA in order to build a performance model for an 
application. Lastly, we describe how we obtain feature importance, how 
this represents an inferred resource utilization profile 
(IRUP) and the algorithm (and alternative heuristics) to comparing 
IRUPs.

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

\begin{table}\caption{
List of stressors used in this paper, along with the categories 
assigned to them by \texttt{stress-ng}. Note that some stressors are 
part of multiple categories.
\label{tbl:stressng-categories}
}
\footnotesize
\input{figures/stressng-categories.tex}
\end{table}

`stress-ng`[@king_stressng_2017] is a tool that is used to "stress 
test a computer system in various selectable ways. It was designed to 
exercise various physical subsystems of a computer as well as the 
various operating system kernel interfaces". There are multiple 
stressors for CPU, CPU cache, memory, OS, network and filesystem. 
Since we focus on system performance bandwidth, we execute the (as of 
version 0.07.29) 42 stressors for CPU, CPU cache, memory and virtual 
memory stressors (@Tbl:stressng-categories shows the list of stressors 
used in this paper). A _stressor_ (or microbenchmark) is a function that loops for a 
fixed amount of time, exercising a particular 
subcomponent of the system. At the end of its execution, `stress-ng` 
reports the rate of iterations executed for the specified period of 
time (referred to as `bogo-ops-per-second`).

\begin{table}\caption{
Table of machines from CloudLab. The last three entries correspond to 
computers in our lab. \label{tbl:machines}
}
\footnotesize
\input{figures/machines.tex}
\end{table}

![Boxplots illustrating the variability of the performance vector 
dataset. Each stressor was executed five times on each of the machines listed in 
@Tbl:machines.
](pipelines/single-node/results/figures/stressng_variability.png){#fig:stressng-variability}

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
others show high correlation between them.

![Heat-map of Pearson correlation coefficients for performance vectors 
obtained by executing `stress-ng` on all the distinct machine 
configurations available in CloudLab.
](pipelines/single-node/results/figures/corrmatrix.png){#fig:corrmatrix}

In order to analyze this last point further, that is, to try to 
discern whether there are a few orthogonal features that we could 
focus on, rather than looking at the totality of the 42 stressors, we 
applied principal component decomposition (PCA) 
[@wold_principal_1987a]. @Fig:pca shows the result. The figure shows 
the relative (blue) and cumulative (green) explained variance ratio. 
As we can see, having 6-8 components would be enough to explain most 
of the variability in the dataset. This confirms what we observe in 
@Fig:corrmatrix, in terms of having many stressors that can be 
explained in function of others. However, doing so would cause the 
loss of information with respect to what stressors are explaining the 
prediction. Instead of trying to reduce the number, we decide to leave 
all the stressors in order to not lose this information. Part of our 
future work is to address whether we can reduce the number of features 
with the goal of improving the models, without having to lose 
information about which stressors are involved in the prediction.

![Principal Component Analysis for the performance vector dataset. The 
y-axis (log-scale) corresponds to the explained variance ratio, while 
the x-axis denotes the number of components. The blue line denotes the 
amount of variance reduced by having a particular number of 
components. The green line corresponds to the cumulative sum of the 
explained variance.
](figures/pca-var-reduction.png){#fig:pca}

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
importances are obtained in order to use them as the IRUP for an 
application. @Fig:irup-generation shows the process applied to 
obtaining IRUPs for an application. `scikit-learn` implements the 
feature importance calculation algorithm introduced in 
[@breiman_classification_1984] and is sketched in the following 
pseudo-code algorithm. Given an ensemble of trees:

 1. Initialize an `f_importance` array to hold a score for each 
    feature in the dataset.

 2. Take an unseen tree of the ensemble and traverse it using the 
    following steps:

     a. For each node that splits on feature $i$, compute the error 
        reduction of that node, multiplied by the number of samples 
        that were routed to the node.

     b. Add this quantity to the `f_importance` array (value 
        corresponding to feature $i$).

     c. Once all nodes are traversed, pick another unseen tree from 
        the ensemble and go to 2.

 3. Assign a score of 100 to the most important feature and normalize 
    the rest of elements in the `f_importance` array with respect to 
    this one.

For step 2.a, the error reduction is recursively defined by obtaining 
the difference between the parent node impurity and the weighted sum 
of the two child node impurities. The impurity criterion depends on 
whether the problem is a classification or regression one. Gini or MSE 
(among many others) can be used for classification. For regression, 
variance impurity is employed and corresponds to the variance of all 
data points that are routed through that node.

We note that before generating a regression model, we normalize the 
data using the `StandardScaler` method from `scikit-learn`, which 
removes the mean (centers it on zero) and scales the data to unit 
variance. Given that the `bogo-ops-per-second` metric does not 
quantify work consistently across stressors, we normalize the data in 
order to prevent some features from dominating in the process of 
creating the prediction models (the data for @Fig:variability has been 
normalized prior to being plotted). In section @Sec:eval we evaluate 
the effectiveness of IRUPs.

## Using IRUPs in Automated Regression Tests {#sec:compare-irups}

As shown in @Fig:pipeline (step 4), when trying to determine whether a 
performance degradation occurred, IRUPs can be used to compare 
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

IRUPs can also be used as a pointer to where to start with an 
investigation that looks for the root cause of the regression 
(@Fig:pipeline, step 5). For example, if _memorymap_ ends up being the 
most important feature, then we can start by looking at any 
code/libraries that make use of this subcomponent of the system. An 
analyst could also trace an application using performance counters and 
look at corresponding performance counters to see which code paths 
make heavy use of the subcomponent in question.

# Evaluation {#sec:eval}

In this section we answer the following questions:

 1. How well can IRUPs accurately capture application performance behavior? 
    (@Sec:effective-irups)
 2. How well can IRUPs work for identifying simulated regressions? 
    (@Sec:irups-for-simulated)
 3. How well can IRUPs work for identifying regressions in real world software 
    projects? (@Sec:irups-for-real)

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
be replicated, as long as the reader has an account at Cloudlab (see 
repo for more details).

## Effectiveness of IRUPs to Capture Resource Utilization Behavior {#sec:effective-irups}

In this subsection we show how IRUPs can effectively describe the 
fine granularity resource utilization of an application with respect 
to a set of machines. Our methodology is:

  1. Given an application $A$, discover relevant performance features 
     using the _quiho_ framework.
  2. Do manual performance analysis of $A$ to corroborate that 
     discovered features are indeed the cause of performance 
     differences.

@Fig:hpccg-irup shows the profile of an execution of the `hpccg` 
miniapp [@heroux_hpccg_2007]. This proxy (or miniapp) application 
[@heroux_improving_2009] is a "conjugate gradient benchmark code for a 
3D chimney domain on an arbitrary number of processors [that] 
generates a 27-point finite difference matrix with a user-prescribed 
sub-block size on each processor." [@heroux_hpccg_2007].

Based on the profile, `stackmmap` and `cache` are the most important 
features. In order to corroborate if this matches with what the 
application does, we profiled this execution with `perf`. The stacked 
profile view shows that ~85% of the time the application is running 
the function `HPC_sparsemv()`. The code for this function is shown in 
@Lst:hpccg-src. As the name implies, this snippet implements a sparse 
vector multiplication function of the form $y=Ax$ where $A$ is a 
sparse matrix and the $x$ and $y$ vectors are dense. By looking at 
this code, we see that the innermost loop iterates an array, 
accumulating the sum of a multiplication. This type of code is a 
potential candidate for manifesting bottlenecks associated with CPU 
cache locality [@akbudak_hypergraph_2013].

```{#lst:hpccg-src .c caption="Source code for bottleneck function in HPCCG."}
int HPC_sparsemv(HPC_Sparse_Matrix *A,
                 const double * const x,
                 double * const y)
{

  const int nrow = (const int) A->local_nrow;

  for (int i=0; i< nrow; i++) {
    double sum = 0.0;
    const double * const cur_vals = 
     (const double * const) A->ptr_to_vals_in_row[i];

    const int    * const cur_inds = 
     (const int    * const) A->ptr_to_inds_in_row[i];

    const int cur_nnz = (const int) A->nnz_in_row[i];

    for (int j=0; j< cur_nnz; j++)
        sum += cur_vals[j]*x[cur_inds[j]];
    y[i] = sum;
  }

  return(0);
}
```

\begin{table}\caption{
Table of performance counters for the HPCCG performance test.
\label{tbl:perf-counters}
}
\footnotesize
\input{figures/perf-counters.tex}
\end{table}

We analyze the performance of this benchmark further by obtaining 
performance counters for the application and comparing the counters 
with those from the top three features (@Tbl:perf-counters shows the 
summary of hardware-level performance counters). Given that hardware 
performance counters are architecture-dependent, we can not make 
generalizations about given that we run an application on a multitude 
of machines. However, we can see that in the case of the `stackmmap` 
stressor, there are some similarities between the counters, specially 
the ones denoting stalled cycles (which significantly determine 
application performance [@cepeda_pipeline_2011 ; 
@mcnairy_itanium_2003]).

Next, we analyze IRUPs of other four applications[^brevity]. These 
applications are Redis [@zawodny_redis_2009], Scikit-learn 
[@pedregosa_scikitlearn_2011], and SSCA [@bader_design_2005]. Due to 
space constraints we omit a similar detailed analysis as the one 
presented above for `hpccg`. However, resource utilization 
characteristics of these code bases is well known and we verify IRUPs 
using this high-level intuition. As a way to illustrate the 
variability originating from executing these applications on an 
heterogeneous set of machines, @Fig:variability shows boxplots of 
these.

![Variability of the five applications presented in this subsection. 
Y-axis has been normalized.
](pipelines/single-node/results/figures/apps_variability.png){#fig:variability}

In @Fig:others we show IRUPs for these four applications. The first 
two on the top correspond to two tests of Redis, a popular open-source 
in-memory key-value database. These two tests are `SET`, `GET` from 
the `redis-benchmark` command that test operations that store and 
retrieve key-value pairs into/from the DB, respectively. The resource 
utilization profiles suggest that `SET` and `GET` are memory intensive 
operations (first 3 stressors from each test, as shown in 
@Tbl:stressng-categories), which is an obvious conclusion. 

![IRUPs for the four tests benchmarked in this section.
](pipelines/single-node/results/figures/four.png){#fig:others}

The next two IRUPs (below) correspond to performance tests for 
Scikit-learn and SSCA. In the case of Scikit-learn, this test runs a 
comparison of a several classifiers in on a synthetic dataset. 
Scikit-learn uses NumPy [@walt_numpy_2011] internally, which is known 
to be memory-bound. The profile is aligned to this known behavior 
since the `zero` microbenchmark stresses access.

The last application is SSCA, a graph analysis benchmark comprising of 
a data generator and 4 kernels which operate on the graph. The 
benchmark is designed to have very little locality, which causes the 
application to generate a many cache misses. As shown in the profile, 
the first feature corresponds to the `cache` stressor, which as it was 
explained earlier, stresses the CPU cache by generating a non-locality 
workload.

[^brevity]: For brevity, we omit other results that corroborate IRUPs 
can correctly identify resource utilization patterns. All these are 
available in the github repository associated to this article.

## Simulating Regressions {#sec:irups-for-simulated}

In this section we test the effectiveness of _quiho_ to detect 
performance simulations that are artificially induced. We induce 
regression by having a set of performance tests that take, as input, 
parameters that determine their performance behavior, thus simulating 
different "versions" of the same application. In total, we have 10 
benchmarks for which we can induce several performance regressions, 
for a total of 20 performance regressions. For brevity, in this 
section we present results for two applications, MariaDB 
[@widenius_mariadb_2009] and a modified version of the STREAM 
benchmark.

The MariaDB test is based on the `mysqlslap` utility for stressing the 
database engine. In our case we run the data loading test, which populates a 
database whose schema is specified by the user. We have a 
fixed set of parameters that load a 10GB database. One of the exposed 
parameters is the one that selects the backend (storage engine in 
MySQL terminology). While the workload and test parameters are the 
same, the code paths are distinct and thus present different 
performance characteristics. The two engines we use in this case are 
`innodb` and `memory`. @Fig:mariadb-innodb-vs-memory shows the 
profiles of MariaDB performance for these two engines.

![MariaDB with innodb and in-memory backends.
](pipelines/single-node/results/figures/mariadb-innodb-vs-memory.png){#fig:mariadb-innodb-vs-memory}

The next test is a modified version of the STREAM benchmark 
[@mccalpin_memory_1995], which we refer to as STREAM-NADDS (introduced 
in [@hutcheson_memory_2011]). This version of STREAM introduces a 
`NADDS` pre-processor parameter that controls the number additions for 
the `Add` test of the STREAM benchmark. In terms of the code, when 
`NADDS` equals to 1 is equivalent to the "vanilla" STREAM benchmark. 
For any value greater than 1, the code adds a new term to the sum 
being executed. Intuitively, since the vanilla version of STREAM is 
memory bound, so adding more terms to the sum causes the CPU to do 
more work, eventually moving the bottleneck from memory to being 
cpu-bound; the higher the value of the `NADDS` parameter, the more 
cpu-bound the test gets. @Fig:stream-adds shows this behavior.

![General behavior of the STREAM-NADDS performance test. The y-axis is 
the throughput of the test in MB/s. The x-axis corresponds to the 
number of terms in the sum expression of the `Add` STREAM subtest. The 
regular ("vanilla") STREAM add test is memory bound, so adding more 
terms to the `Add` subtest moves the performance from memory- to 
cpu-bound; the higher the value of the `NADDS` parameter, the more 
CPU-bound the test gets. This test was executed across all available 
machines (5 times). The bars denote standard deviation.
](pipelines/single-node/results/figures/stream-nadds-behavior.png){#fig:stream-adds}

@Fig:stream-irups shows the IRUPs for the four tests. On the left, 
we see the resource utilization behavior of the "vanilla" version of 
STREAM (which corresponds to a value of 1 for the `NADDS` parameter). 
As expected, the associated features (stressors) to these are from the 
memory/VM category, in particular `vecmath`. As the number of terms 
for the sum increases, the test moves all the way to being CPU-bound 
(at `NADDS=30`), which can be seen by observing the `bsearch` and 
`hsearch` features going up in importance as the number of additions 
increases.

![The IRUPs for modified version of STREAM. The parameter of `NADDS` 
increases by taking values of 1, 2, 4, ..., 20 and 30. We see that 
they capture the simulated regression which causes this application to 
be moving from being memory-bound to being cpu-bound.
](pipelines/single-node/results/figures/stream-nadds.png){#fig:stream-irups}

## Real world Scenario {#sec:irups-for-real}

In this section we show that _quiho_ works with regressions that can 
be found in real software projects. It is documented that the changes 
made to the `innodb` storage engine in version 10.3.2 improves the 
performance in MariaDB, with respect to previous version 5.5.58. If we 
take the development timeline and invert it, we can treat 5.5.58 as if 
it was a "new" revision that introduces a performance regression. To 
show that this can be captured with IRUPs, we use `mysqlslap` again 
and run the `load` test. @Fig:mariadb-innodb-regression shows the 
corresponding IRUPs. We can observe that the IRUP generated by 
_quiho_ can identify the difference in performance.

![A regression that appears from going in the reversed timeline (from 
mariadb-10.0.3 to 5.5.38).
](pipelines/single-node/results/figures/mariadb-innodb-regression.png){#fig:mariadb-innodb-regression}

For brevity, we omit regressions found in other 4 applications (zlog, 
postgres, redis, and apache web server).

[^popper-url]: http://falsifiable.us
[^gh]: http://github.com/ivotron/quiho-popper

# Discussion {#sec:discussion}

We briefly discuss some aspects related to _quiho_.

**Application-Independent Performance Characterization**. We used a 
subset of `stress-ng` microbenchmarks to quantify machine performance 
but the approach is not limited to this benchmarking toolkit. Ideally, 
we would like to extend the amount and type of stressors so that we 
have more coverage over the distinct subcomponents of a system. An 
open question is to systematically test whether the current set of 
stressors is sufficient to cover all subcomponents of a system, and at 
the same time reduce the number of microbenchmarks.

**Falsifiability of IRUPs** The reader might have noticed that, regardless of how the performance 
of an application looks like, SRA will always produce a model with 
associated feature importances. Thus, one can pose the following 
question: is there any scenario where a IRUP is _not_ correctly 
associated with what the application is doing? In other words, are 
IRUPs falsifiable? The answer is yes. A IRUP can be incorrectly 
representing an application's performance behavior if there is under- 
or over-fitting when generating the model. @Fig:underfit (left) shows 
the correlation matrix obtained from a dataset containing only 3 data 
points (generated by selecting two random machines from the set of 
available ones). Almost all stressors are highly correlated among each 
other, which suggests (as explained in @Sec:quiho) there is little 
that a prediction model can learn about the underlying resource 
utilization behavior of an application in this dataset (which contains 
only 4 points, coming from two machines with very similar 
characteristics). This is confirmed by looking at the IRUP of an 
application obtained from this small dataset (@Fig:underfit (right)). 
The application in this case is `redis-set` and if we compare this 
IRUP with the one in @Fig:others we can observe that the most 
important features are CPU- (`af-alg` and `hsearch`) and IO-intensive 
(`resources`) related, which is not what we observe in practice from 
this dataset. The correlation matrix shows why this is so: almost all 
the features are highly correlated. One way of determining the right 
amount of machines needed in order to generate good models is to apply 
PAC [@valiant_theory_1984] to this dataset in order to quantify the 
probability of obtaining highly accurate estimations.

![Correlation matrix and IRUP for `redis-set`, obtained from only two 
randomly selected machines from @Tbl:machines (`issdm-41` and `r320` 
in this case).
](pipelines/single-node/results/figures/underfit.png){#fig:underfit}

**Quiho vs. other tools**. The main advantage of _quiho_ over other 
performance profiling tools is that it is automatic and 100% 
hands-off. As mentioned before, the main assumption being that there 
exist performance vectors (or they are obtained when the as part of 
the test) for a sufficiently varied set of machines. We see _quiho_ as 
a complement, not a replacement of `perf`, to existing performance 
engineering practices: once a test has failed _quiho_'s checks, then 
proceed to make use of existing tools.

**IRUP Comparison**. The algorithm specified in @Sec:compare-irups 
is a straight-forward one. One could think of more sophisticated ways 
of doing IRUP comparison and finding equivalences. For example, using 
the categories from @Tbl:stressng-categories, one could try to group 
stressors and determine coarse-grained bottlenecks, instead of fine 
grained ones. Another alternative is to do reduce the number of 
features by applying PCA, exploratory factor analysis (EFA), or 
singular value decomposition (SVD), and compare profiles in terms of 
the mapped factors.

**IRUP as a visualization tool**. The reader might have noticed that 
IRUPs can be visually compared by the human eye (and are somewhat 
similar in this regard to FlameGraphs [@gregg_flame_2016]). Adding a 
coloring scheme to IRUPs might make it easier to interpret the 
differences. For example, the categories in @Tbl:stressng-categories 
could be used to define a color palette (by assigning a color to each 
subset of the powerset of categories).

**Reproducibility**. Providing performance vectors alongside 
experimental results allows to preserve information about the 
performance characteristics of the underlying system that an 
experiment observed at the time it ran. This is a quantifiable 
snapshot that provides context and facilitates the interpretation of 
results. Ideally, this information could be used as input for 
emulators and virtual machines, in order to recreate original 
performance characteristics.

**Reinforcement Learning**. Over the course of its life, an application 
will be tested on many platforms. If we can have an ever-growing list 
of machines where an application is tested, the more we run an 
application in a scenario like this, the more rich the performance 
vector dataset (and associated application performance history). This 
can serve as the foundation to applycbecomes we learn about its 
properties. For example, if we had performance vectors captured as 
part of executions of the Phoronix benchmark suite (which has public 
data on <openbenchmarking.org), we could leverage such a dataset to 
create rich performance models.

# Related Work {#sec:sra}

**Automated Regression Testing**. Automated regression testing 
[@perl_performance_1993] can be broken down in the following three 
steps. 1) In the case of large software projects, decide which tests 
to execute [@kazmi_effective_2017]. This line of work is complementary 
to _quiho_. 2) Once a test executes, decide whether a regression has 
occurred [@syer_continuous_2014]. This can be broken down in mainly 
two categories, as explained in [@shang_automated_2015]: pair-wise 
comparisons and model assisted. _quiho_ fits in the latter category, 
the main difference being that, as opposed to existing solutions, 
_quiho_ does not rely on having accurate prediction models since its 
goal is to describe resource utilization (obtain IRUPs). 3) If a 
regression is observed, automatically find the root cause or aid an 
analyst to find it [@ibidunmoye_performance_2015 ; 
@heger_automated_2013 ; @attariyan_xray_2012]. While _quiho_ does not 
find the root cause of regressions, it complements the information 
that an analyst has available to investigate further.

**Profiling-based Performance Modeling**. Modeling performance based 
on application profiles has been studied before 
[@snavely_modeling_2001 ; @ghaith_profilebased_2013a ; 
@shen_automating_2015]. In [@snavely_modeling_2001], the MAPS 
benchmark is used to characterize the performance of machines. These 
profiles are then convoluted with application traces obtained by the 
MetaSim tool in order to obtain a prediction on the performance of an 
application. In [@shen_automating_2015] the authors use randomized 
optimization (genetic algorithms) to systematically explore the 
parameter space of an application in order to create a record of 
`<input, runtime>` pairs. _quiho_ can be used in this case to augment 
the available information and have an IRUP associated to the inputs of 
the application under study.

**Performance Profile Visualization**. An IRUP can be used to 
visualize performance and thus have a resemblance with a flame graph 
[@gregg_flame_2016]. In [@bezemer_understanding_2015] the authors 
introduce the concept of differential flame grahps, which can be used 
to visually compare the changes between two or more flame graphs. A 
similar approach could be applied to IRUPs in order to visualize the 
differences between two flame graphs.

**Inducing Performance Regressions**. In [@chen_exploratory_2017], the 
authors analyzed the code repositories of two open source projects in 
order to device a way of systematically inducing performance 
regressions. Our methodology instruments an application in order to 
parametrize performance and control when changes in performance are 
triggered, as a way of testing methods that are aimed at detecting 
these changes.

**Decision Trees In Performance Engineering**. In 
[@jung_detecting_2006] the authors use decision trees to detect 
anomalies and predict performance SLO violations. They validate their 
approach using a TPC-W workload in a multi-tiered setting. In 
[@shang_automated_2015], the authors use performance counters to build 
a regression model aimed at filtering out irrelevant performance 
counters. In [@nguyen_automated_2012a], the approach is similar but 
statistical process control techniques are employed instead. In the 
case of _quiho_, the goal is to use decision trees as a way of 
obtaining feature performance, thus, as opposed to what it's proposed 
in [@shang_automated_2015], the leaves of the generated decision trees 
contain actual performance predictions instead of the name of 
performance counters

**Correlation-based Analysis and Supervised Learning**. Correlation 
and supervised learning approaches have been proposed in the context 
of software testing, mainly for detecting anomalies in application 
performance [@ibidunmoye_performance_2015]. In the former, runtime 
performance metrics are correlated to application performance using a 
variety of distinct metrics. In supervised learning, the goal is the 
same (build prediction models) but using labeled datasets. Decision 
trees are a form of supervised learning, however, given that _quiho_ 
applies regression rather than classification techniques, it does not 
rely on labeled datasets. Lastly, _quiho_ is not intended to be used 
as a way of detecting anomalies, although we have not analyzed its 
potential use in this scenario.

# Limitations and Future Work {#sec:conclusion}

The main limitation in _quiho_ is the requirement of having to execute 
a test on more than one machine in order to obtain IRUPs. On the other 
hand, we can avoid having to run `stress-ng` every time the 
application gets tested by integrating this into the infrastructure 
(e.g., system administrators can run `stress-ng` once a day or once a 
week and make this information for every machine available to users).

We are currently working in adapting this approach to profile 
distributed and multi-tiered applications. We also plan to analyze the 
viability of applying _quiho_ in multi-tenant configurations and to 
profile long-running (multi-stage) applications such as a web-service 
or big-data applications. In these cases, we would define windows of 
time and apply _quiho_ to each. The main challenge in this scenario is 
to automatically define the windows in such a way that we can get 
accurate profiles.

In the era of cloud computing, even the most basic computer systems 
are complex multi-layered pieces of software, whose performance 
properties are difficult to comprehend. Having complete understanding 
of the performance behavior of an application, considering the 
parameter space (workloads, multi-tenancy, etc.) is challenging. One 
application of _quiho_ we have in mind is to couple it with automated 
black-box (or even gray-box) testing frameworks to improve our 
understanding of complex systems.

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
