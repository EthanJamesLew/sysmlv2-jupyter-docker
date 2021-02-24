FROM openjdk:17-slim

##
## This Dockerfile is specifically designed for execution at mybinder.org
##

## wget is used to retrieve Conda and SysML Release. Inkscape and LaTeX is
## required for rendering notebooks as PDFs.
RUN apt-get --quiet --yes update && apt-get install -yqq \
  wget                        \
  inkscape                    \
  texlive-fonts-recommended   \
  texlive-generic-recommended \
  texlive-xetex

##
## Non-root user is a requirement of Binder:
##   https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html
##
ARG NB_USER=sysml
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

USER root
RUN chown -R ${NB_UID} ${HOME}

USER ${NB_USER}

WORKDIR /home/${NB_USER}

##
## Miniconda installation page:
## https://docs.conda.io/en/latest/miniconda.html#linux-installers
##
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

## Defining the RELEASE down here ensures that the previous comamnds can
## be recycled since they're not affected by the release version.
ARG RELEASE=2020-10

##
## SysML page: https://github.com/Systems-Modeling/SysML-v2-Release
##
RUN wget -q https://github.com/Systems-Modeling/SysML-v2-Release/archive/${RELEASE}.tar.gz

## Install MiniConda
RUN chmod 755 /home/${NB_USER}/Miniconda3-latest-Linux-x86_64.sh
RUN mkdir /home/${NB_USER}/conda
RUN /home/${NB_USER}/Miniconda3-latest-Linux-x86_64.sh -f -b -p /home/${NB_USER}/conda
RUN /home/${NB_USER}/conda/condabin/conda init

## Install SysML
RUN tar xzf ${RELEASE}.tar.gz

WORKDIR /home/${NB_USER}/SysML-v2-Release-${RELEASE}/install/jupyter

## This is the path that conda init setups but conda init has no effect
## here, so setup the PATH by hand. Else install.sh won't work.
ENV PATH="/home/${NB_USER}/conda/bin:/home/${NB_USER}/conda/condabin:/usr/local/openjdk-17/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RUN ./install.sh

WORKDIR /home/${NB_USER}/SysML-v2-Release-${RELEASE}/

## Move any files in the top level directory to the doc directory
RUN find . -maxdepth 1 -type f -exec mv \{\} doc \;

COPY ["notebooks/SysML - State Charts.ipynb",     \
      "notebooks/SysML - Decision Example.ipynb", \
      "./"]

## Trust the notebooks so that the SVG images will be displayed.
RUN jupyter trust ./*.ipynb
