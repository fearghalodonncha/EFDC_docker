# Building:
#       docker build --tag dev-deepcurrent:efdc . -f Dockerfile
# Note that if DNS issues arise it may help to specify the network explicitly
#       docker build --network=host --tag dev-deepcurrent:efdc . -f Dockerfile
# Running with information on what "node" it runs:
#        docker run -h node01 --name cont1 -it efdc /bin/bash
# Running with sharing of the directory "work" and
# full access to physical memory:
#       docker run --volume /Users/fearghal/Work/EFDC/:/home/efdc/work/ --name=cont1 -it dev-deepcurrent:efdc /bin/bash
# Removing intermediate images and inactive containers afterwards:
#       docker images -q --filter dangling=true | xargs docker rmi
#       docker rm $(docker ps -qa --no-trunc --filter "status=exited")
# Extracting for sharing on another machine:
#       docker save dev-deepcurrent:efdc > deepcurrent-cpu-ubuntu.tar
# Loading on another machine:
#       docker load < deepcurrent-cpu-ubuntu.tar


FROM ubuntu:19.10

MAINTAINER Fearghal O'Donncha <feardonn@ie.ibm.com>

ENV USER efdc

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USER} 


RUN apt-get clean 
RUN apt-get update 
RUN apt-get install -y --no-install-recommends build-essential \
    apt-utils openssh-server wget openmpi-doc binutils vim \
    git make gcc gfortran m4 zlib1g-dev libopenmpi-dev openmpi-bin openmpi-common \ 
    openmpi-doc binutils python3-dev python3-numpy python3-pip python3-virtualenv \ 
    python3-matplotlib python3-tk python3-setuptools
 
RUN apt-get install -y --no-install-recommends libnetcdf-dev libnetcdff-dev
RUN apt-get install -y --no-install-recommends libblas-dev liblapack-dev
RUN apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /tmp/src-temp
WORKDIR /tmp/src-temp

# Create MPI configuration options
RUN mkdir /var/run/sshd
RUN echo 'root:${USER}' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login 
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# ------------------------------------------------------------
# Add an user and name efdc
# ------------------------------------------------------------
#### CLEAN UP ####
WORKDIR /
RUN rm -rf /tmp/*

RUN adduser --disabled-password --gecos "" ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ------------------------------------------------------------
# Set-Up SSH with our Github deploy key
# ------------------------------------------------------------

ENV SSHDIR ${HOME}/.ssh/

RUN mkdir -p ${SSHDIR}

ADD ssh/config ${SSHDIR}/config
ADD ssh/id_rsa.mpi ${SSHDIR}/id_rsa
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/id_rsa.pub
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/authorized_keys

RUN chmod -R 600 ${SSHDIR}* && \
    chown -R ${USER}:${USER} ${SSHDIR}

# ------------------------------------------------------------
# Configure OpenMPI
# ------------------------------------------------------------

RUN rm -fr ${HOME}/.openmpi && mkdir -p ${HOME}/.openmpi
ADD default-mca-params.conf ${HOME}/.openmpi/mca-params.conf
RUN chown -R ${USER}:${USER} ${HOME}/.openmpi



RUN pip3 install --no-cache-dir --upgrade pip 
ADD requirements.txt / 
RUN pip3 install --no-cache-dir -r requirements.txt 


# ------------------------------------------------------------
# Clone EFDC source code and sample setups
# ------------------------------------------------------------

ENV TRIGGER 1
RUN mkdir ${HOME}/Efdc_src
RUN git clone https://github.com/fearghalodonncha/DeepCurrent.git ${HOME}/Efdc_src/
RUN chown -R ${USER}:${USER} ${HOME}/Efdc_src; \
    cd ${HOME}/Efdc_src/Src; \
    make; 


EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
