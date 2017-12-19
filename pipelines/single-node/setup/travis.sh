#!/bin/bash
set -x

docker stop node1
docker rm node1

set -e

docker run -d --name=node1 \
  -p 2221:22 \
  -e ADD_INSECURE_KEY=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp \
  ivotron/python-sshd:debian-9

echo "node1 ansible_host=localhost ansible_port=2221 ansible_user=root" > geni/machines

cat > vars.yml << EOL
install_facter: false
test_timeout: 600
benchmarks:
- name: stressng
  image: ivotron/stress-ng:v0.07.29
  command: --sequential 1 --timeout 5 --metrics-brief --times --yaml /results/stressng.yml --exclude apparmor,affinity,aio,aiol,cap,chdir,chmod,chown,chroot,clock,clone,context,copy-file,cpu-online,fp-error,daemon,dccp,dentry,dir,dirdeep,dnotify,dup,epoll,eventfd,exec,fallocate,fanotify,fault,fcntl,fiemap,fifo,filename,flock,fork,fstat,futex,get,getdent,getrandom,handle,hdd,icmp-flood,inotify,io,iomix,ioprio,itimer,kcmp,key,kill,klog,lease,link,locka,lockf,lockofd,madvise,membarrier,memfd,mergesort,mknod,mlock,mmapfork,mmapmany,mq,msg,netlink-proc,nice,null,open,personality,pipe,poll,procfs,pthread,ptrace,pty,quota,rdrand,readahead,rename,rlimit,rtc,schedpolicy,sctp,seal,seccomp,seek,sem,sem-sysv,sendfile,sigfd,sigfpe,sigpending,sigq,sigsegv,sigsuspend,sleep,sock,sockfd,sockpair,spawn,splice,switch,symlink,sync-file,sysfs,sysinfo,tee,timer,timerfd,tlb-shootdown,tmpfs,tsc,udp,udp-flood,unshare,urandom,utime,userfaultfd,vfork,vforkmany,wait,xattr,yield,wcs,zombie,zlib
  privileged: true
  cap_add:
  - ALL
  volumes:
  - '/tmp/results:/results'
  fetch:
  - '/tmp/results'
- name: scikit-learn
  image: ivotron/scikit-learn-bench:0.18.1
  volumes:
  - '/tmp/results:/results'
  fetch:
  - '/tmp/results'
EOL

# get insecure key out of container
docker run --rm \
  -v `pwd`:/mnt \
  --entrypoint=/bin/bash \
  ivotron/python-sshd:debian-9 -c 'cp /root/.ssh/insecure_rsa /mnt'
sudo chown $USER:$USER insecure_rsa
mv insecure_rsa $HOME/.ssh/id_rsa
