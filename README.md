# _quiho_

[![build][1]][2] [![binder][3]][4] [![zenodo][5]][6]

[1]: https://travis-ci.org/ivotron/quiho-popper.svg?branch=master
[2]: https://travis-ci.org/ivotron/quiho-popper
[3]: http://mybinder.org/badge.svg
[4]: http://beta.mybinder.org/v2/gh/ivotron/quiho-popper/master
[5]: https://zenodo.org/badge/83738959.svg
[6]: https://zenodo.org/badge/latestdoi/83738959

[Popper](http://github.com/systemslab/popper) repository for the 
_quiho_ paper:

Ivo Jimenez, Noah Watkins, Michael Sevilla, Jay Lofstead, and Carlos 
Maltzahn. 2018. _quiho_: Automated Performance Regression Testing Using Inferred 
Resource Utilization Profiles. [_In ICPE '18: ACM/SPEC International Conference 
on Performance Engineering, April 9–13, 2018, Berlin, Germany_](https://icpe2018.spec.org/). ACM, New York, 
NY, USA, 12 pages. https://doi.org/10.1145/3184407.3184422

This repository contains experiments, results, and manuscript. 

# Getting Started

This repository contains all artifacts necessary to replicate results 
or re-generate the PDF. For the replicating results, there are two 
main components:

  * Analysis. [`pandas`](https://pandas.pydata.org/) and 
    [`sklearn`](http://scikit-learn.org) are used to obtain fine 
    granularity resource utilization profiles (FGRUPs). For 
    instructions on how to replicate these results, see 
    [here](#analysis).

  * Data Generation. To generate the data that is used in the analysis 
    part, one has to re-execute the micro-benchmarks and applications 
    mentioned in the paper. See [here](#experiment) for a complete 
    guide.

Assuming one has Docker installed locally (we have only tested on 
Linux and OSX), the following re-executes both, data generation and 
the analysis:

```bash
cd quiho-popper/pipelines/single-node
export CI=1
./setup.sh
./run.sh
./post-run.sh
./validate.sh
./teardown.sh
```

Quick description of what these commands do:

  * `setup.sh`. setups the infrastructure to run the experiment, 
    depending of where this is executed.
      * `setup/travis.sh`. When the `CI` environment variable is 
        defined, this "boots" a "node" on the machine where this 
        script is executed, using Docker.
      * `setup/cloudlab.sh`. Allocates as many different nodes as 
        possible from all the available in CloudLab (and federated 
        GENI) sites.

  * `run.sh`. Invokes 
    [`baseliner`](https://github.com/ivotron/baseliner) to run the 
    data generation step on all the available machines. The list of 
    machines as well as the variables of the experiment 
    [`vars.yml`](pipelines/single-node/vars.yml) are used in this 
    step.

  * `post-run.sh`. Post-process the data gathered by the previous 
    step.

  * `validate.sh`. Executes the analysis contained in the notebook and 
    double-checks that images contained in the article are generated.

  * `teardown.sh`. If the experiment ran on CloudLab, this script 
    releases all machines used by the experiment.

# Replicating Results

## Analysis

All the plots in the article were obtained from [this Jupyter 
notebook](https://github.com/ivotron/quiho-popper/blob/master/pipelines/single-node/results/visualize.ipynb) 
in this repository. The notebook contains the source code for all 
plots, as well as others that didn't fit due to space constraints. 
GitHub renders Notebooks on the browser, so you should be able to see 
the graphs and the code directly on your browser if you click on the 
link.

If you need to re-run the analysis, the 
[`datapackage/`](pipelines/single-node/datapackage/) folder contains 
the raw data that can be used to re-execute the analysis. To interact 
with the notebook in real-time, you can click on 
[![Binder](http://mybinder.org/badge.svg)](http://beta.mybinder.org/v2/gh/ivotron/quiho-popper/master), 
which will open a live [Jupyter](https://jupyter.org) notebook. To 
re-run the notebook, click on `Cell->Run All` (more info on how to use 
Jupyter [here](http://jupyter.org/documentation.html)).

Alternatively, if you have [Docker](http://docker.com) installed, you 
can launch a local Jupyter server, clone this repo to your machine and 
analyze locally:

```bash
cd quiho-popper/

docker run --rm -d -p 8888:8888 \
  -v `pwd`:/home/jovyan \
  jupyter/scipy-notebook start-notebook.sh --NotebookApp.token=""

# go to http://localhost:8888
```

## Experiment

Re-executing the experiment requires having compute resources 
available. If you happen to have a cluster of machines available, then 
you can follow the steps on the [On-premises](#on-premises) section. 
These should be Linux machines with [Docker](https://docs.docker.com) 
and `rsync` installed, as well as passwordless SSH (and `sudo`) 
access.

> **NOTE**: The _quiho_ approach relies on having as much performance 
> variability as possible among the machines it's running on. So 
> running on a cluster of homogeneous machines won't replicate the 
> results in the paper.

### On-premises

The main experiment requires 
[Docker](https://docs.docker.com/engine/installation/) to be installed 
on your machine. To execute:

 1. Write a `quiho-popper/geni/machines` file following the 
    [Ansible](http://docs.ansible.com/ansible/latest/intro_inventory.html) 
    inventory format (an INI-like file). For example:

    ```
    node1.my.domain ansible_user=myuser
    node2.my.domain ansible_user=myuser
    node3.my.domain ansible_user=myuser
    ```

 2. If you need to, edit the `vars.yml` file in order to update any 
    parameters of the experiment.

 3. Define a `SSHKEY` variable containing the path or value of the SSH 
    key used to authenticate with the hosts.

 4. Execute the `run.sh` script.

The following is an example bash session:

```bash
cd quiho-popper/pipelines/single-node

# edit machines file to add the hostnames of machines you have available
# vim quiho-popper/machines file

# edit any parameters to the experiment
# vim vars.yml

export SSHKEY=`~/.ssh/mysshkey`

./run.sh
```

### CloudLab

The data in the paper was obtained by running the experiment on 
CloudLab. It is possible to re-execute the experiment, provided one 
has an account there. After creating an account:

 1. Obtain credentials (see 
    [here](http://docs.cloudlab.us/geni-lib/intro/creds/cloudlab.html)). 
    This will result in having a `cloudlab.pem` file on your machine.
 2. Clone this repository.
 3. Create the following environment variables:

      * `CLOUDLAB_USER`. Your user at CloudLab.
      * `CLOUDLAB_PASSWORD`. Your password for CloudLab.
      * `CLOUDLAB_PROJECT`. The name of the project your account 
        belongs to on CloudLab.
      * `CLOUDLAB_PUBKEY_PATH`. The path to your SSH key registered 
        with CloudLab.
      * `CLOUDLAB_SSHKEY_PATH`. The path to your **private** SSH key 
        registered with CloudLab.
      * `CLOUDLAB_CERT_PATH`. The path to the `cloudlab.pem` file 
        downloaded in step 1.

 4. Run the following steps:

    ```bash
    cd quiho-popper/pipelines/single-node
    ./setup.sh
    ./run.sh
    ./post-run.sh
    ./validate.sh
    ./teardown.sh
    ```

### Travis

The experiment is continuously tested via Travis. To run a test on 
Travis yourself:

 1. Fork this repository to your GitHub account.

 2. Login to [TravisCI](https://travis-ci.org) using your GitHub
    credentials and enable Travis awesomeness on your fork (see guide
    [here](https://docs.travis-ci.com/user/getting-started/#To-get-started-with-Travis-CI)).

 3. Trigger an execution by creating and pushing a commit to your 
    fork. For example, modify the `vars.yml` file and commit it. Or to 
    trigger with an empty commit do:

    ```bash
    git commit -m 'trigger TravisCI build' --allow-empty
    ```

    **NOTE**: TravisCI has a limit of 2 hours, after which the test is 
    terminated and failed. For this reason, the `setup/travis.sh` 
    modifies the `vars.yml` in order to generate parameters that take 
    shorter to run (approx 15 mins). The test in this case only 
    obtains one data point for one application (`sklearn`).

# How To Evaluate

One alternative workflow for evaluating these artifacts:

  1. Inspect the bash scripts located in the
     [`pipelines/single-node`](pipelines/single-node) folder. The 
     [Getting Started](#getting-started) section above gives a 
     high-level view of what each script does. In particular, the 
     [`vars.yml`](pipelines/single-node/vars.yml) file contains the 
     complete list of all the benchmarks executed for the paper.

  2. Quickly testing that the pipeline works on a subset of 
     benchmarks:

       * If testing locally, see the [Getting Started 
         section](#getting-started).
       * If using Travis, see the [Travis section above](#travis).

     The list of applications that is defined for this test is 
     [here](https://github.com/ivotron/quiho-popper/blob/master/pipelines/single-node/setup/travis.sh#L23).

  3. If reviewers have access to compute resources or an account at 
     CloudLab, the full data generation step can be executed (see 
     [On-Premises](#on-premises) or [CloudLab](#cloudlab)).

  4. Click on [![zenodo][5]][6] badge to verify that there's an archive of 
     this repository. Beside the infrastructure dependencies (Linux 
     hosts running Docker), there are several dependencies:

        * Benchmarks that get executed. These are maintained 
          separately in [this 
          repository](https://github.com/ivotron/docker-bench/) and 
          all are available at [this DockerHub 
          account](https://hub.docker.com/u/ivotron/).

        * [`baseliner`](https://github.com/ivotron/baseliner), the 
          test driver that executes the benchmarks on remotes 
          machines. This is [maintained separately](https://github.com/ivotron/baseliner) and docker images 
          are available on the corresponding [DockerHub 
          repository](https://hub.docker.com/r/ivotron/baseliner/).

        * When executing on CloudLab, the
          [`geni-lib`](https://bitbucket.org/emulab/geni-lib) python 
          library is used to automate the allocation of machines. This 
          is packaged as a [Docker 
          container](https://github.com/ivotron/docker-geni-lib) and 
          images are available on 
          [DockerHub](https://hub.docker.com/r/ivotron/geni-lib/).

        * [Jupyter](http://jupyter.org/) data science stack. These 
          Docker images are [maintained by the Jupyter 
          project](https://github.com/jupyter/docker-stacks/) and 
          images are available on 
          [DockerHub](https://hub.docker.com/r/jupyter/scipy-notebook).

     Given that compressing all these dependencies would result in a 
     very large file, we have left them out of the tarball that has 
     been submitted for review. However, we would be happy to make 
     [tarballs for 
     each](https://docs.docker.com/engine/reference/commandline/save/) 
     available upon request.
