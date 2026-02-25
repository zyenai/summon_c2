# Dragos C2 Deploy

These scripts exist to automate the setup and teardown of Dragos C2 infrastructure for penetration test engagments, such as EC2 instances and supporting cloud network infrastructure. All infrastructure items are tagged with the engagement lead and customer name, enabling easy identification and decommission after an engagement. 

At a high level, this project has five main components:

- `docker_build.sh` builds our Docker image, installing all the necessary packages for Ansible

- `docker_start.sh` starts our Docker environment and maps directories like `~/.aws/` and `~/.ssh/`

- `create_c2.yml` is the playbook that creates all of our C2 infrastructure

- `update_c2.yml` is the playbook that updates packages, updates and licenses Cobalt Strike, and sets up HTTP/HTTPS/DNS forwarding

- `remove_c2.yml` is the playbook that decomissions all of our C2 infrastructure

# Docker Setup
The instructions below assume you are have Docker installed and working on Linux (https://docs.docker.com/desktop/install/linux-install/) or on Windows using WSL2 (https://docs.docker.com/desktop/install/windows-install/).

The Docker daemon binds to a Unix socket, not a TCP port. By default it's the `root` user that owns the Unix socket, and other users can only access it using `sudo`. The Docker daemon always runs as the `root` user. 

To run Docker as a non-root user (such as `kali`), and to properly map user files (`~/.ssh/`, `~/.aws/`, etc.), add your user to the `docker` group by running the following commands:

1. Create the docker group.
    ```
    sudo groupadd docker
    ```
2. Add your user to the docker group.
    ```
    sudo usermod -aG docker $USER
    ```
3. Log out and log back in so that your group membership is re-evaluated.

    If you're running Linux in a virtual machine, it may be necessary to restart the virtual machine for changes to take effect.

    You can also run the following command to activate the changes to groups:
    ```
    newgrp docker
    ```

4. Verify that you can run `docker` commands without `sudo`.
    ```
    docker run hello-world
    ```
    This command downloads a test image and runs it in a container. When the container runs, it prints a message and exits.

## Common issues

If you get the error:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Try starting Docker Desktop through Windows, or run the following command in your WSL command prompt:
```
sudo dockerd
```

If you get the error:

```
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.40/containers/json: dial unix /var/run/docker.sock: connect: permission denied
```

‌Try running:
```
sudo chmod 666 /var/run/docker.sock
```

# Usage

1. Open or create the file `~/.aws/credentials`
    ```sh
    user@ubuntu:~$ touch ~/.aws/credentials
    ```

2. Navigate to the [AWS console](https://d-9067771c16.awsapps.com/start#/)

3. Expand the `aws-workloads-tocpentest-prod` directory, then select `Command line or programmtic access`

4. Copy `Option 2`

5. Paste the credentials  into the `~/.aws/credentials` file.
    ```sh
    ┌──(kali㉿kali)-[~/]
    └─$ cat ~/.aws/credentials 
    [546135455042_AWSPowerUserAccess]
    aws_access_key_id=*
    aws_secret_access_key=*
    aws_session_token=*
    ```

6. Make sure you have a [key pair](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#KeyPairs:v=3;$case=tags:false%5C,client:false;$regex=tags:false%5C,client:false) ready for SSH authentication to AWS, an SSH config file (it doesn't have to have anything in it), and that all your SSH directory/file permissions [are correct](https://jonasbn.github.io/til/ssh/permissions_on_ssh_folder_and_files.html):  
    ```sh
    ┌──(kali㉿kali)-[~/]
    └─$ ls -la ~/.ssh
    total 36
    drwx------  2 kali kali 4096 Dec  9 15:53 .
    drwx------ 23 kali kali 4096 Dec  9 15:27 ..
    -rw-------  1 kali kali   20 Dec  9 11:46 config
    -rw-------  1 kali kali 6310 Dec  9 15:09 known_hosts
    -rw-------  1 kali kali 5190 Dec  9 15:02 known_hosts.old
    -rw-------  1 kali kali 2455 Dec  4 17:45 twebb_aws
    -rw-r--r--  1 kali kali  564 Dec  4 17:45 twebb_aws.pub
    ```

7. Clone or copy and unzip the `dragos_c2_deploy.zip` to your home directory.
    ```sh
    ┌──(kali㉿kali)-[~/]
    └─$ unzip dragos_c2_deploy.zip
    ```

8. Change into the dragos_c2_deploy directory.
    ```sh
    ┌──(kali㉿kali)-[~/]
    └─$ cd dragos_c2_deploy
    ```

9. Copy the `vars/vars.template` file to `vars/vars.yml`, then add your variables to the `vars/vars.yml` file. 

    Protip: Check your external IP via commandline with: `curl -k https://api.ipify.org?format=json`

    ```sh
    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ cp group_vars/all.template group_vars/all.yml
    
    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ vi group_vars/all.yml # input your engagement-specific variables, see below for examples

    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ cat vars/vars.yml 
    # ./group_vars/all.yml
    ansible_ssh_private_key_file: ~/.ssh/aws_private_key
    ansible_user: ubuntu
    aws_profile: 546135455042_AWSPowerUserAccess
    aws_region: us-east-1
    availability_zone: us-east-1a
    c2_subdomain: lol.gothos.com
    customer: dragos
    engagement_lead: anomander_rake
    image_id: ami-007855ac798b5175e
    key_name: aws_private_key
    local_ip: 158.146.20.99/32
    subnet_cidr: 10.6.66.0/24
    ```

10. Run the `docker_build.sh` script to build the Docker container that contains all the dependencies for Ansible. 
    
    Note: You only need to run this script at initial build, or if there are updates that need to be made to the Docker image. 
    
    ```sh
    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ ./docker_build.sh
    Sending build context to Docker daemon  14.27MB
    Step 1/34 : FROM ubuntu:22.04
    ...
    Successfully built 08238aa4ecd2
    Successfully tagged ansible:latest
    Successfully tagged ansible:dragos_c2_deploy
    ```

11. Run the `docker_start.sh` script to enter the Docker container.
    ```sh
    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ ./docker_start.sh
    To run a command as administrator (user "root"), use "sudo <command>".
    See "man sudo_root" for details.

    ansible@bdc45d7a8a36:/ansible$
    ```

12. Use the `ansible-playbook` command to launch the `create_c2.yml` playbook. This playbook creates all our AWS infrastructure and works some SSH config magic to make connections a breeze later on. 
    ```sh
    ansible@c3988fa458fd:/ansible$ ansible-playbook create_c2.yml  
    ```

13. If playbook runs successfully, you should see an output like this with no `failed` statuses.
    ```sh
    TASK [Print C2 infrastructure info] ***************************************************************
    ok: [localhost] => {
        "msg": [
            "VPC ID - vpc-0c0dc65e6bb41c631",
            "Subnet ID - subnet-0d345eacaa50f18e2",
            "Subnet CIDR - 10.6.66.0/24",
            "Gateway ID - igw-0b7f395dcac3adbed",
            "Teamserver Instance ID - i-0b27b5a451b182d7b",
            "Teamserver Security Group ID - sg-02b0c8b296360c0f8",
            "Teamserver Private IP - 10.6.66.252",
            "Teamserver Public IP - 18.206.242.59",
            "Teamserver Public DNS - ec2-18-206-242-59.compute-1.amazonaws.com",
            "Redirector Instance ID - i-089f751083dbd85fe",
            "Redirector Security Group ID - sg-08df6630a55a2aa25",
            "Redirector Private IP - 10.6.66.132",
            "Redirector Public IP - 3.90.137.135",
            "Redirector Public DNS - ec2-3-90-137-135.compute-1.amazonaws.com",
            "Cobalt Strike DNS Host - lol.dragoat.com"
        ]
    }

    PLAY RECAP **************************************************************************************
    localhost                  : ok=24   changed=12   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

    ansible@2f9c3e56c6f2:/ansible$
    ```

14. Confirm Redirector and Teamserver instance creation in [AWS EC2 Management Console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceState=running). Once both EC2 instances show `3/3 checks passed` in the `Status Check` column in the [AWS EC2 Management Console](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceState=running), proceed to run the `update_c2.yml` playbook. Enter the [Cobalt Strike license key](https://dragos.secretservercloud.com/app/#/secrets/24565) when prompted. This playbook updates OS packages, installs Cobalt Strike, sets up HTTP/HTTPs/DNS forwarding, and makes some other quality of life improvements. 
    ```sh
    ansible@c3988fa458fd:/ansible$ ansible-playbook update_c2.yml 
    What cobalt strike license should I use?: f9aa-XXX-XXXX-0001

    PLAY [localhost] *********************************************************************************************************
    ...
    PLAY RECAP ***************************************************************************************************************
    ec2-34-228-208-251.compute-1.amazonaws.com : ok=23   changed=15   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    ec2-54-162-77-144.compute-1.amazonaws.com : ok=23   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    localhost                  : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    ```

15. Because the  `create_c2.yml` playbook set up a unique SSH config file for this particular engagement, you can now log into the Teamserver with a single command! Simply run `ssh team_<customername>` to log into the Teamserver via a proxyjump through the Redirector.
    ```sh
    ┌──(kali㉿kali)-[~/dragos_c2_deploy]
    └─$ ssh team_test 
    Warning: Permanently added '3.90.137.135' (ECDSA) to the list of known hosts.
    Warning: Permanently added '10.6.66.252' (ECDSA) to the list of known hosts.
    Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1031-aws x86_64)

    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/pro

    System information as of Mon Dec  9 22:25:45 UTC 2024

    System load:  0.0               Processes:             100
    Usage of /:   4.1% of 77.35GB   Users logged in:       0
    Memory usage: 10%               IPv4 address for ens5: 10.6.66.252
    Swap usage:   0%


    Expanded Security Maintenance for Applications is not enabled.

    0 updates can be applied immediately.

    Enable ESM Apps to receive additional future security updates.
    See https://ubuntu.com/esm or run: sudo pro status


    *** System restart required ***
    You are on the Kyberite Teamserver
    Private IP: 10.6.66.252
    Public IP: 18.206.242.59
    Redirector Public IP: 3.90.137.135
    To start the Cobalt Strike Teamserver, run: 'teamserver 3.90.137.135 <password> [/path/to/c2.profile] [YYYY-MM-DD]'
    Happy hacking!
    ```

16. The unique `config_<customername>` SSH config also includes a local forward on port 50050, so after you've logged into the Teamserver and started Cobalt Strike, all you need to do now is launch the Cobalt Strike client locally.
    ```sh
    ┌──(kali㉿kali)-[~/cobaltstrike/client]
    └─$ ./cobaltstrike    
    ```

17. To remove all the C2 infrastructure you created, run the `remove_c2.yml` playbook. 
    ```sh
    ansible@2f9c3e56c6f2:/ansible$ ansible-playbook remove_c2.yml
    ```