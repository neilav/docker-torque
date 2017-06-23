FROM ubuntu
MAINTAINER Neil Venables <neil.venables@cruk.manchester.ac.uk>

RUN apt-get update &&\
            apt-get update -y &&\
            apt-get install build-essential -y &&\
            apt-get install git -y &&\
            apt-get install libtool m4 automake pkg-config -y &&\
            apt-get install libssl-dev libxml2-dev zlib1g-dev libboost-dev pbs-drmaa-dev gperf -y

RUN git clone https://github.com/adaptivecomputing/torque.git -b 6.1.1 /usr/local/6.1.1
WORKDIR /usr/local/6.1.1
RUN ./autogen.sh &&\
    ./configure --enable-drmaa &&\
    make &&\
    make install

ENV HOSTNAME master
COPY ./scripts/set_hostname.sh /

# Configure local Torque
RUN ldconfig &&\
    /set_hostname.sh &&\
    echo "$HOSTNAME" > /var/spool/torque/server_name &&\
    echo "y" | pbs_server -t create &&\
    sleep 2 &&\
    trqauthd &&\
    qmgr -c "set server acl_hosts=$HOSTNAME" &&\
    qmgr -c "set server scheduling=true" &&\
    qmgr -c "create queue batch queue_type=execution" &&\
    qmgr -c "set queue batch started=true" &&\
    qmgr -c "set queue batch enabled=true" &&\
    qmgr -c "set queue batch resources_default.nodes=1" &&\
    qmgr -c "set queue batch resources_default.walltime=3600" &&\
    qmgr -c "set server default_queue=batch" &&\
    qmgr -c "set server keep_completed = 10" &&\
    echo "$HOSTNAME np=1" > /var/spool/torque/server_priv/nodes &&\
    printf "\$pbsserver $HOSTNAMEt \n\$logevent 255" > /var/spool/torque/mom_priv/config

RUN adduser --disabled-password --gecos '' batchuser

COPY ./scripts/startenv.sh /

RUN apt-get install environment-modules wget unzip default-jre -y
WORKDIR /usr/local/
RUN wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip && unzip fastqc_v0.11.5.zip
RUN chmod 755 FastQC/fastqc
RUN mkdir -p /usr/share/modules/modulefiles/apps/
COPY ./scripts/fastqc-0.11.5 /usr/share/modules/modulefiles/apps/

RUN apt-get install python3 python3-pip -y
RUN echo "source /etc/profile.d/modules.sh" >> /root/.bashrc
RUN echo "alias python='/usr/bin/python3'" >> /root/.bashrc
RUN echo "alias pip='/usr/bin/pip3'" >> /root/.bashrc

WORKDIR /
ENTRYPOINT /startenv.sh && /bin/bash
