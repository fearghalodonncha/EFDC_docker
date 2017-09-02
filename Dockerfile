# Build this image:  docker build -t efdc .
# Run the image as root: docker run -h node01 --name cont1 -it efdc /bin/bash

FROM ubuntu:16.04

MAINTAINER Fearghal O'Donncha <feardonn@ie.ibm.com>

ENV USER efdc

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USER} 


RUN apt-get update -y && \
    apt-get install -y --no-install-recommends sudo build-essential && \
    apt-get install -y --no-install-recommends sudo apt-utils && \
    apt-get install -y --no-install-recommends openssh-server wget \
        python-dev python-numpy python-pip python-virtualenv python-matplotlib \
        git make gcc gfortran m4 zlib1g-dev libopenmpi-dev openmpi-bin openmpi-common openmpi-doc binutils && \
    apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

 RUN mkdir /tmp/src-temp
 WORKDIR /tmp/src-temp

# Add NetCDF & OpenBlas libraries
# 1) We need HDF
     #Required for NetCDF integration; source is supported at http://www.hdfgroup.org/ftp/HDF5/current/src

ARG HDF_VERSION="1.10.1"  
# Download build and install HDF5
RUN wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.10.1.tar.bz2; \
    tar -xjvf hdf5-${HDF_VERSION}.tar.bz2; \ 
    cd hdf5-${HDF_VERSION}; \
    ./configure --enable-shared --prefix=/usr/local/hdf5; \
    make;  \
    make install; \
    cd ..;  \
    rm -rf /hdf5-${HDF_VERSION} /hdf5-${HDF_VERSION}.tar.bz2; 

# 2)
#Build netcdf 
# First we need to build NetCDF C version 
# (http://www.unidata.ucar.edu/software/netcdf/docs/getting_and_building_netcdf.html)
# Download and install netcdf C

 ARG NCD_VERSION="4.3.3.1"
 RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NCD_VERSION}.tar.gz; \ 
 tar xzvf netcdf-${NCD_VERSION}.tar.gz; \
   cd netcdf-${NCD_VERSION}; \
   ./configure --prefix=/usr/local/netcdf CC=gcc LDFLAGS=-L/usr/local/hdf5/lib CFLAGS=-I/usr/local/hdf5/include; \
   make ; \ 
   make install;\ 
   cd .. ;\ 
   rm -rf netcdf-${NCD_VERSION} netcdf-${NCD_VERSION}.tar.gz

# 3) Build NetCDF fortran version
# (http://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html)
# Download and install NetCDF fortran
ARG NCF_VERSION="4.4.2"
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-${NCF_VERSION}.tar.gz; \
     tar -xzvf netcdf-fortran-${NCF_VERSION}.tar.gz;  \
    cd netcdf-fortran-${NCF_VERSION}; \
    ./configure --prefix=/usr/local/netcdf \
                 --disable-fortran-type-check \
                CC=gcc \ 
                FC=gfortran \
                LDFLAGS=-L/usr/local/netcdf/lib \
                CFLAGS=-I/usr/local/netcdf/include; \
    make ;  \
    make install; \
    cd ..//.. ;  \
    rm -rf /tmp/src-temp

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

RUN pip install --upgrade pip \
    && pip install -U setuptools 

# ------------------------------------------------------------
# Configure OpenMPI
# ------------------------------------------------------------

RUN rm -fr ${HOME}/.openmpi && mkdir -p ${HOME}/.openmpi
ADD default-mca-params.conf ${HOME}/.openmpi/mca-params.conf
RUN chown -R ${USER}:${USER} ${HOME}/.openmpi

# ------------------------------------------------------------
# Clone EFDC source code and sample setups
# ------------------------------------------------------------

ENV TRIGGER 1
RUN mkdir ${HOME}/Tutorial
RUN git clone https://github.com/fearghalodonncha/DeepCurrent.git ${HOME}/Tutorial/
RUN chown -R ${USER}:${USER} ${HOME}/Tutorial; \
    cd ${HOME}/Tutorial/Src; \
    make; 

ENV LD_LIBRARY_PATH="/usr/local/netcdf/lib:${LD_LIBRARY_PATH}"

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
