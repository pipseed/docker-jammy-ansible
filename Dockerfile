# Docker file for my Home Lab
FROM ubuntu:22.04

LABEL maintainer="pipseed@gmail.com"
LABEL version="v1.0"

ARG DEBIAN_FRONTEND=noninteractive

# Fix for https://github.com/pypa/pip/issues/10219
ARG LANG="en_GB.UTF-8"
ARG LC_ALL="en_GB.UTF-8"

ENV pip_packages "ansible"

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       gpg-agent \
       build-essential \
       locales \
       libffi-dev \
       libssl-dev \
       libyaml-dev \
       python3-dev \
       python3-setuptools \
       python3-pip \
       python3-yaml \
       software-properties-common \
       rsyslog systemd systemd-cron sudo iproute2 \
    && apt-get clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man
RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Upgrade pip to latest version.
RUN pip3 install --upgrade pip

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_GB.UTF-8

# Install Ansible via Pip.
RUN pip3 install cryptography
RUN pip3 install docker
RUN pip3 install $pip_packages

COPY initctl_faker .
RUN chmod +x initctl_faker && rm -fr /sbin/initctl && ln -s /initctl_faker /sbin/initctl

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

# Remove unnecessary getty and udev targets that result in high CPU usage when using
# multiple containers with Molecule (https://github.com/ansible/molecule/issues/1104)
RUN rm -f /lib/systemd/system/systemd*udev* \
  && rm -f /lib/systemd/system/getty.target

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
CMD ["/lib/systemd/systemd"]
