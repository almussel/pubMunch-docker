FROM ubuntu

MAINTAINER Audrey Musselman-Brown, almussel@ucsc.edu

RUN apt-get update && apt-get install -y git python-gdbm python-pip xvfb firefox wget
RUN pip install numpy
RUN pip install biopython pygr requests selenium==3.3.0 pyvirtualdisplay html2text==2016.9.19 synapseclient
RUN pip install ga4gh==0.3.5 || true

ADD wrapper.sh /opt/wrapper.sh
ADD pubs_json.py /opt/pubs_json.py
ADD getpubs.py /opt/getpubs.py
RUN chmod +x /opt/*

RUN mkdir /work
WORKDIR /work

RUN wget  https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-linux64.tar.gz
RUN tar xzf geckodriver-v0.15.0-linux64.tar.gz  -C /usr/local/bin && rm geckodriver-v0.15.0-linux64.tar.gz

RUN git clone -b brca --single-branch https://github.com/almussel/pubMunch.git

RUN mkdir /work/pubMunch/external
# FIXME: switch to a more stable link -- look in cgl-docker-lib for example
#RUN wget -O /work/pubMunch/external/pdfbox-app-2.0.4.jar http://mirror.symnds.com/software/Apache/pdfbox/2.0.4/pdfbox-app-2.0.4.jar 
#RUN wget -O /work/pubMunch/external/doc2txt-1.4.tgz https://sourceforge.net/projects/docx2txt/files/latest/download

# set entrypoint
ENTRYPOINT ["/opt/wrapper.sh"]

