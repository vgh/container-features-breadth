# Notes: 
# - Each separate line of code below creates a separate layer (a tarfile)
#   that becomes part of the set of files that contribute to the image. So bundling
#   related shell commands together (say, everything to do with apt) for RUN 
#   is a standard practice.
# - Caching of layers is the default. So only when a line of code changes does that 
#   layer (and subsequent layers) get rebuilt. There are cases when this is not 
#   what is needed.  The following command builds without cache:
#     docker compose build --no-cache
# References:
# - Docker best practices:
#   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#   Note that some snippets in this documentation do not work without additional 
#   steps on Ubuntu 22.04.

# Use the standard Ubuntu 22.04 image.  This based image supports multiple architectures.
# However, some individual commands below are linux/amd64 architecture specific.
FROM ubuntu:22.04

# '/bin/sh -c' is the default shell that Docker uses during image builds, and the 
# version  of sh on Ubuntu does not support 'set -o pipefail'.  That is bad since a 
# pipeline should terminate as soon as a command in the pipeline fails.  So, use 
# '/bin/bash -c' as the install during the image build instead.
SHELL ["/bin/bash", "-c"]

# ARG is for variables that should only be accessible during the image build.
# Use a specific version of the S6 overlay.  See:
# https://github.com/just-containers/s6-overlay
ARG S6_OVERLAY_VERSION=3.1.5.0

# ENV is for variables that will be accessible both during the image build
# and when the image is running.
# Ubuntu uses 'apt' for the package manager, and that package manager 
# sometimes prompts for user input unless the DEBIAN_FRONTEND environment
# variable is set to 'noninteractive'
ENV DEBIAN_FRONTEND=noninteractive
# Environment variables needed for Python development
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

# Bundling everything to do with apt together in one long command line, and
# cleaning up afterward. This is a pretty standard practice.  'apt install' 
# MUST be given the '-y' option to prevent it from prompting during the build,
# and the '-qq' option is to reduce the verbosity of apt just a bit.
RUN apt -y update && apt -y dist-upgrade && apt -y -qq install \
      bzip2 \
      ca-certificates \
      curl \
      g++ \
      git \
      tmux \
      tzdata \
      vim \
      wget \
      xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Python development using miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -ay && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# This is an alternative to using ADD for the URLs and RUN for the untar 
# commands as is done in the s6-overlay documentation at
# https://github.com/just-containers/s6-overlay
# The method here is closer to the Docker best practices since it does not 
# write tarfiles to disk as a separate step. This helps minimize image size.
RUN set -o pipefail && curl -SL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar Jxpf - -C /
RUN set -o pipefail && curl -SL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz | tar Jxpf - -C /

# Run S6 as the entrypoint
ENTRYPOINT ["/init"]
CMD ["/bin/bash"]
