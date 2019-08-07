FROM bioperl/bioperl
MAINTAINER Govind Chandra <govind.chandra@jic.ac.uk>
# ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -yqq ncbi-blast+ hmmer unzip wget git
RUN apt-get install -yqq sqlite3 build-essential python-dev python-pip
RUN apt-get install -yqq bioperl
# latest biopython version doesn't work
RUN pip install -q biopython==1.69

# The Pfam database
RUN mkdir -p /home/work/pfam
ADD ripp.hmm /home/work/pfam/
ADD prodigal-short /usr/local/bin/


WORKDIR /home/work
RUN git clone https://github.com/bikdm12/ripper.git
WORKDIR /home/work/ripper
RUN git checkout feature-local_gbk



WORKDIR /home/work/pfam
RUN wget --no-verbose ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
# RUN wget --no-verbose ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz
# hmms from tigrfams ftp site are incompatible with Pfam since they are made with another hmmer version
RUN wget --no-verbose -O TIGRFAMs_15.hmm.gz https://www.dropbox.com/s/kiy68796gc1exm7/TIGRFAMs_15.hmm.gz?dl=1
RUN gunzip *.gz

# && rm Pfam-A.hmm

# RUN cat /home/work/ripper/ripp.hmm >> Pfam-A.hmm
RUN cat ripp.hmm TIGRFAMs_15.hmm>> Pfam-A.hmm
RUN hmmpress Pfam-A.hmm
RUN hmmpress ripp.hmm


WORKDIR /home/work

RUN mkdir -p /home/work/sqlite
RUN mkdir -p /home/work/pfamscan
# RUN mkdir -p /home/work/ripper

#

WORKDIR /home/work
RUN git clone https://github.com/bikdm12/rodeo2.git

RUN cp ripper/ripper_run.sh ripper/minitest.txt ripper/local.conf ./
RUN cp ripper/postprocess.sh ./

WORKDIR /home/work