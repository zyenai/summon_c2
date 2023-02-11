#!/bin/bash

docker build --build-arg USERNAME=ansible -t ansible:latest -t ansible:c2_deploy .
