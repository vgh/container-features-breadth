From ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt -y update && apt -y dist-upgrade \
    && apt -y install vim tmux wget && apt clean

