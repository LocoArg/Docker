FROM debian:8.5

#En ves de usar el contenedor de continuumio/anaconda3 pongo todo en un archivo

MAINTAINER Emiliano Chaves <chaves.emiliano@gmail.com>

#Paso 1
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
#Paso 2
RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion
#Paso 3
RUN apt-get install -y --no-install-recommends \
        ed \
        less \
        locales \
        vim-tiny 
#Paso 4 creo el usuario y la carpeta
RUN useradd emiliano \
    && mkdir /home/emiliano \
    && chown emiliano:emiliano /home/emiliano \
    && addgroup emiliano staff
#Paso 5 se instala Miniconda puede ser tambien Anaconda
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.1.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh
#Paso 6 se instala Tini para que funcione correctamente Jupyter
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean


#Paso 7
    
ENV PATH /opt/conda/bin:$PATH

#Paso 8 Se instala Jupyter 

RUN conda install jupyter -y

#Paso 9
RUN apt-get install gcc -y

#Paso 10 instalar las extensiones

RUN pip install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master
#Paso 11
RUN jupyter contrib nbextension install 
#Paso 12 como es miniconda no tiene instalado nada
RUN conda install -c anaconda-nb-extensions nb_conda_kernels=1.0.3

#Paso 13
RUN cp /root/.jupyter/jupyter_notebook_config.json /root/.jupyter/jupyter_notebook_config.bak
#Paso 14
RUN cp /opt/conda/etc/jupyter/jupyter_notebook_config.json /opt/conda/etc/jupyter/jupyter_notebook_config.bak
#Paso 15
RUN json='{ "NotebookApp": {"kernel_spec_manager_class": "nb_conda_kernels.CondaKernelSpecManager"}}'
#Paso 16
RUN echo $json > /opt/conda/etc/jupyter/jupyter_notebook_config.json
#Paso 17
RUN json2='{ "NotebookApp": { "nbserver_extensions": { "jupyter_nbextensions_configurator": true, "nbpresent":true, "nb_conda":true, "nb_anacondacloud":true }, "kernel_spec_manager_class":"nb_conda_kernels.CondaKernelSpecManager" } }'
#Paso 18
RUN echo $json2 > /root/.jupyter/jupyter_notebook_config.json

#Instalamos R

#Paso 19
## Use Debian unstable via pinning -- new style via APT::Default-Release
RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
    && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default
#Paso 20
ENV R_BASE_VERSION 3.3.1

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
#Paso 21
RUN apt-get update \
    && apt-get install -t unstable -y --no-install-recommends \
        littler \
                r-cran-littler \
        r-base=${R_BASE_VERSION}* \
        r-base-dev=${R_BASE_VERSION}* \
        r-recommended=${R_BASE_VERSION}* \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*
#Paso 22
RUN echo '' > /etc/apt/apt.conf.d/default
#Paso 23
RUN apt-get update
#Paso 24
RUN apt-get install -y --no-install- recommends libssl-dev libssh-dev libgdal-dev libproj-dev libcairo-dev libcurl4-openssl-dev
#Install the r packages

#Paso 25 Instalo los paquetes de R 
RUN install2.r --error \
    repr \
    IRdisplay \
    curl \
    evaluate \ 
    crayon \ 
    pbdZMQ \ 
    uuid \ 
    digest \ 
    devtools \
    dplyr \
    ggplot2 \
    ggthemes \
    httr \
    knitr \
    revealjs \
    tidyr \
    servr \
    shiny \
    stringr \
    svglite \
    tibble \
    tufte \
    xml2 \
    ggmap \
    rgdal  


#Paso 26
# install R packages for IRkernel (GitHub)

RUN echo "devtools::install_github('IRkernel/IRkernel')" > setupIRkernel && Rscript setupIRkernel

#Paso 27
# register IRkernel w/ jupyter
RUN echo "IRkernel::installspec(user=FALSE)" > setupIRkernel && Rscript setupIRkernel && rm setupIRkernel
#Paso 28
 #Debe ingresar a R y ejecutar devtools::install_github('IRkernel/IRkernel')
RUN echo "IRkernel::installspec(user=FALSE)" > setupIRkernel && Rscript setupIRkernel && rm setupIRkernel
#Paso 29
 RUN pip install rpy2 geocoder
#Paso 30
# RUN pip install geocoder
#Paso 31 
#RUN apt-get upgrade -y
#Paso 32
#RUN apt-get autoremove -y; \
 #    apt-get clean -y
#Paso 33
ENTRYPOINT [ "/usr/bin/tini", "--" ]
#Paso 34
CMD /bin/bash
#Paso 35
EXPOSE 8888
#Paso 36
RUN conda update -y python conda && \
  conda install -y --no-deps \
  matplotlib \
  cycler \
  freetype \
  libpng \
  pyparsing \
  pytz \
  python-dateutil \
  scikit-image \
  networkx \
  pillow \
  six \
  && conda clean -tipsy
#Paso 37
RUN conda install -y \
  pip \
  setuptools \
  notebook \
  ipywidgets \
  terminado \
  psutil \
  numpy \
  scipy \
  pandas \
  bokeh \
  scikit-learn \
  statsmodels \
  && conda clean -tipsy

COPY jupyter_notebook_config.json1 /root/.jupyter/jupyter_notebook_config.json

COPY jupyter_notebook_config.json2 /opt/conda/etc/jupyter/jupyter_notebook_config.json 

ENTRYPOINT jupyter notebook --no-browser --ip=0.0.0.0 --port 8888 --notebook-dir=/home/emiliano


