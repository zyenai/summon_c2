#!/bin/bash

docker build --build-arg USERNAME=ansible -t ansible:latest -t ansible:dragos_c2_deploy .
