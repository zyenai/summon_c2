#!/bin/bash
sudo socat TCP4-LISTEN:443,fork TCP4:front_private_ip:443 >/dev/null 2>&1 &
sudo socat TCP4-LISTEN:80,fork TCP4:front_private_ip:80 >/dev/null 2>&1 &