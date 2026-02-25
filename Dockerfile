FROM ubuntu:22.04
# Run this build with the following command:
# docker build --build-arg USERNAME=ansible -t ansible:latest .
# Afterwards you can start the containter as such:
# docker run --rm -it -v $(pwd)\:/ansible ansible

# This is too early for add-apt-repository... but we don't need it anyway
# RUN add-apt-repository --yes --update ppa:ansible/ansible
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
       apt-get -y --quiet --no-install-recommends install \
       python3-pip software-properties-common git \
       gcc python3-dev libkrb5-dev ssh rsync \
       sudo curl groff less unzip
# Add Zscaler certificate to Ubuntu instance
ADD ZscalerRootCertificate-2048-SHA256.crt /usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt
RUN chmod 644 /usr/local/share/ca-certificates/ZscalerRootCertificate-2048-SHA256.crt && update-ca-certificates
# Install AWS CLI
RUN arch=$(arch) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN rm -rf ./aws
RUN rm awscliv2.zip
# Install other necessary packages
RUN pip install --upgrade pip
RUN pip install pywinrm[kerberos]
RUN DEBIAN_FRONTEND=noninteractive \
       apt-get -y --quiet --no-install-recommends install \
       krb5-user
RUN pip install pywinrm
RUN pip install proxmoxer
RUN pip install requests
# RUN pip install ansible-core
RUN pip install ansible
RUN pip install boto3 botocore
RUN ansible-galaxy collection install community.vmware
RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection install amazon.aws
RUN ansible-galaxy collection install community.crypto
RUN ansible-galaxy collection install ansible.windows
RUN ansible-galaxy install nvjacobo.caddy
# RUN pip install -r ~/.ansible/collections/ansible_collections/community/vmware/requirements.txt
   # This next file doesn't seem to exist... whoops... That is ok, we already solved this...
   #  && pip install -r ~/.ansible/collections/ansible_collections/community/general/requirements.txt
RUN apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

ARG USERNAME
RUN adduser --disabled-password --gecos '' ${USERNAME} \
    && adduser ${USERNAME} sudo                        \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir /ansible
RUN mkdir /home/ansible/.ssh
RUN mkdir /home/ansible/.aws
RUN chown -R ${USERNAME}:${USERNAME} /home/ansible/.ssh
RUN chown -R ${USERNAME}:${USERNAME} /home/ansible/.aws
# Run container as non-root user from here onwards
USER ${USERNAME}
# RUN mkdir /home/${USERNAME}/ansible/
# WORKDIR /home/${USERNAME}/ansible/
WORKDIR /ansible
# run bash when container is started
ENTRYPOINT [ "/bin/bash" ]