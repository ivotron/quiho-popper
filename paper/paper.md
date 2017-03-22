---
title: "_quiho_: Sensitivity Analysis of Applications for Discovering 
Hardware Factors Affecting Performance"
author:
- name: "  "
  affiliation: "  "
  email: "  "
abstract: |
  We introduce a framework for discovering system features that affect 
  the performance of an application. We do this by applying 
  Sensitivity Analyisis (regression in particular) using 
  hardware-independent feature vectors.
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

Understanding changes in performance due to hardware is 
time-consuming.

# The _quiho_ Sensitivity Analysis Framework

## `stress-ng`

Every stressor can be mapped to a basic features of the underlying 
platform. For example, STREAM to memory bandwidth, `zero` to memory 
mapping, `qsort` to sorting data, etc.

## Our Approach

Steps for analyzing an application:

  1. Obtain feature vectors for the underlying platform.
  2. Run application and select metric of interest (e.g. bandwidth)
  3. Apply decision tree regression.

# Evaluation

**Methodology** - For every workload:

  1. Discover relevant features using quiho.
  2. Analyze code to corroborate that discovered features are indeed 
     the cause of performance differences.

# Related Work {#sec:related}

There exists related work, currently compiling and reading it.

# Conclusion and Future Work {#sec:conclusion}

We need to find more things.

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
