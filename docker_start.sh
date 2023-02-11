#!/bin/bash

docker run \
        --rm \
        -it \
        -v "$(pwd)"\:/ansible \
        -v "$(pwd)"/ansible.cfg\:/etc/ansible/ansible.cfg \
        -v ~/.ssh\:/home/ansible/.ssh \
        -v ~/.aws\:/home/ansible/.aws \
        ansible
