# _quiho_

[![Binder](http://mybinder.org/badge.svg)](http://beta.mybinder.org/v2/gh/ivotron/quiho-popper/master)

The [Popper](http://github.com/systemslab/popper) repository for the 
_quiho_ paper submission. Contains experiments, results, and 
manuscript.

# Replicating Results

The `experiments/single-node` folder contains the main experiment of the 
paper.

## Analysis

Every figure in the article has a `[source]` link in its caption 
that points to a Jupyter notebook in this repository. The 
notebook contains the analysis and source code for the figure (and 
possibly others). GitHub renders Notebooks on the browser, so you 
should be able to see the graphs and the code (for example 
[this](https://github.com/ivotron/quiho-popper/blob/master/experiments/single-node/results/visualize.ipynb)). 
If you need to re-run the analysis, the parent folder of the notebook 
(following the 
[Popper](http://popper.readthedocs.io/en/latest/protocol/intro_to_popper.html#repository-structure)'s 
file organization convention) contains results that can be used to 
re-execute the analysis. To interact with these notebooks in 
real-time, you can click the Binder icon above (or here 
[![Binder](http://mybinder.org/badge.svg)](http://beta.mybinder.org/v2/gh/ivotron/quiho-popper/master)), 
which will open a live [Jupyter](https://jupyter.org) notebook. 


Alternatively, if you have [Docker](http://docker.com) installed, you 
can clone this repo to your machine and run:

```bash
cd quiho-popper/

docker run --rm -d -p 8888:8888 \
  -v `pwd`:/home/jovyan/work \
  jupyter/scipy-notebook start-notebook.sh --NotebookApp.token=""
```

Then point your browser to 
[`http://localhost:8888`](http://localhost:8888).

## Experiment

Re-executing the experiment requires having compute resources 
available. If you happen to have a cluster of machines available, then 
you can follow the steps on the "On-premises" section. These should be 
Linux machines with [Docker](https://docs.docker.com) installed, and 
passwordless SSH access.

> **NOTE**: The _quiho_ approach relies on having as much variability 
as possible between the nodes it's running on. So running on a cluster 
of homogeneous machines won't replicate the results in the paper.

### On-premises

The main experiment requires 
[Docker](https://docs.docker.com/engine/installation/) to be installed 
on your machine. To execute:

 1. Write a `quiho-popper/geni/machines` file following the 
    [Ansible](http://docs.ansible.com/ansible/latest/intro_inventory.html) 
    inventory format (an INI-like file).

 2. If you need to, edit the `vars.yml` file in order to update any 
    parameters of the experiment. For example:

    ```
    node1.my.domain ansible_user=myuser
    node2.my.domain ansible_user=myuser
    node3.my.domain ansible_user=myuser
    ```

 3. Define a `SSHKEY` variable containing the path or value of the SSH 
    key used to authenticate with the hosts.

 4. Execute the `run.sh`.

The following is an example bash session:

```bash
cd quiho-popper/experiments/single-node

# edit machines file to add the hostnames of machines you have available
# vim quiho-popper/machines file

# edit any parameters to the experiment
# vim vars.yml

export SSHKEY=`~/.ssh/mysshkey`

./run.sh

```

### Via TravisCI

This experiment is executed on CloudLab, so you need an account there. 
After creating an account:

 1. Obtain credentials (see 
    [here](http://docs.cloudlab.us/geni-lib/intro/creds/cloudlab.html)). 
    This will result in having a `cloudlab.pem` file on your machine.
 2. Fork this repository to your GitHub account.
 3. Login to [TravisCI](https://travis-ci.org) using your GitHub 
    credentials and enable Travis awesomeness on your fork (see guide 
    [here](https://docs.travis-ci.com/user/getting-started/#To-get-started-with-Travis-CI)).
 4. Create the following environment variables (see guide 
    [here](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings)):

      * `CLOUDLAB_USER`. Your user at CloudLab.
      * `CLOUDLAB_PASSWORD`. Your password for CloudLab.
      * `CLOUDLAB_PROJECT`. The name of the project your account 
        belongs to on CloudLab.
      * `CLOUDLAB_PUBKEY`. The value of your SSH key registered with 
        CloudLab.
      * `CLOUDLAB_SSHKEY`. The value of your **private** SSH key 
        registered with CloudLab.
      * `CLOUDLAB_CERT`. The value of the key contained in the 
        `cloudlab.pem`.

    All these have to be strings (not paths) and they need to be 
    properly escaped.

    **NOTE**: Make sure to enable leave the `Display value in build 
    log` OFF. Otherwise, these will be available.

 5. Trigger an execution by pushing a commit. For example, modify the 
    `vars.yml` file and commit it. Or to trigger with an empty commit 
    do:

    ```bash
    git commit -m 'trigger TravisCI build' --allow-empty
    ```

**NOTE:** TravisCI has a limit of 120 minutes for a test, after which 
a test is timed out and marked as failed. So you might want to 
configure the experiment for a short run, for example, this should run 
in a relatively short time:

```yaml
- name: stressng
  image: ivotron/stress-ng:v0.07.29
  command: --sequential 1 --timeout 10 --metrics-brief --times --yaml /results/stressng.yml --exclude apparmor,affinity,aio,aiol,bind-mount,cap,chdir,chmod,chown,chroot,clock,clone,context,copy-file,cpu-online,daemon,dccp,dentry,dir,dirdeep,dnotify,dup,epoll,eventfd,exec,fallocate,fanotify,fault,fcntl,fiemap,fifo,filename,flock,fork,fstat,fp-error,futex,get,getdent,getrandom,handle,hdd,icmp-flood,inotify,io,iomix,ioprio,itimer,kcmp,key,kill,klog,lease,link,locka,lockf,lockofd,madvise,membarrier,memfd,mergesort,mknod,mlock,mmapfork,mmapmany,mq,msg,netlink-proc,nice,open,personality,pipe,poll,procfs,pthread,ptrace,pty,quota,rdrand,readahead,rename,rlimit,rtc,schedpolicy,sctp,seal,seccomp,seek,sem,sem-sysv,sendfile,sigfd,sigfpe,sigpending,sigq,sigsegv,sigsuspend,sleep,sock,sockfd,sockpair,spawn,splice,switch,symlink,sync-file,sysfs,sysinfo,tee,timer,timerfd,tlb-shootdown,tmpfs,tsc,udp,udp-flood,unshare,urandom,userfaultfd,utime,vfork,vforkmany,wait,wcs,xattr,yield,zombie,zlib,zombie
  network_mode: host
  ipc: host
  privileged: true
  cap_add:
  - ALL
  volumes:
  - '/tmp/results:/results'
  fetch:
  - '/tmp/results'

- name: hpccg
  image: ivotron/hpccg:v1.0
  command: 128 128 128
  environment:
    SINGLE_NODE: 1
    MPIRUN_FLAGS: -np 4
  volumes:
  - '/tmp/results:/results'
  fetch:
  - '/tmp/results'
```
