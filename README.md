# C2 Deploy

These scripts exist to automate the setup and teardown of C2 infrastructure for penetration test engagments, such as EC2 instances and supporting cloud network infrastructure. All infrastructure items are tagged with the engagement lead and customer name, enabling easy identification and decommission after an engagement. 

Note: the usage instructions below assume you are have installed [Docker on Linux](https://docs.docker.com/desktop/install/linux-install/) or on [Windows using WSL2](https://docs.docker.com/desktop/install/windows-install/).

At a high level, this project has five main components:

- `docker_build.sh` builds our Docker image, installing all the necessary packages for Ansible

- `docker_start.sh` starts our Docker environment and maps directories like `~/.aws/` and `~/.ssh/`

- `create_c2.yml` is the playbook that creates all of our C2 infrastructure

- `update_c2.yml` is the playbook that updates packages, updates and licenses Cobalt Strike, and sets up HTTP/HTTPS/DNS forwarding

- `remove_c2.yml` is the playbook that removes all of our C2 infrastructure

# Usage

1. Open or create the file `~/.aws/credentials`
    ```sh
    user@ubuntu:~$ touch ~/.aws/credentials
    ```

2. Navigate to the [AWS console](https://aws.amazon.com/console/)

3. Expand the profile you wish to use, then select `Command line or programmtic access`

4. Copy `Option 2`

5. Paste the credentials  into the `~/.aws/credentials` file. Make sure to replace the first line `[my_user_profile_name]` with `[default]` if it is different.
    ```sh
    user@ubuntu:~$ vi ~/.aws/credentials
    ```

6. Clone or copy and unzip the `c2_deploy.zip` to your home directory
    ```sh
    user@ubuntu:~$ unzip c2_deploy.zip
    ```

7. Change into the c2_deploy directory
    ```sh
    user@ubuntu:~$ cd c2_deploy
    ```

8. Add your variables to the `vars/vars.yml` file:
    ```sh
    user@ubuntu:~/c2_deploy$ cat vars/vars.yml
   
    customer: <short_customer_name> 
    engagement_lead: <engagement_lead_name> 
    image_id: <ami-019bd4544c394e302> 
    key_name: <ssh_key_name>
    c2_domain: <subdomain>.domain.com
    aws_profile: <default>
    public_key: "~/.ssh/<ssh_key_name>"
    local_ip: <X.X.X.X/32>
    subnet_cidr: <X.X.X.X/24>
    ```

8. Run the `docker_build.sh` script to build the Docker container that contains all the dependencies for Ansible
    ```sh
    user@ubuntu:~/c2_deploy$ ./docker_build.sh 
    [+] Building 4.3s (36/36) FINISHED
    ...
    ```

9. Run the `docker_start.sh` script to enter the Docker container
    ```sh
    user@ubuntu:~/c2_deploy$ ./docker_start.sh 
    To run a command as administrator (user "root"), use "sudo <command>".
    See "man sudo_root" for details.

    ansible@2f9c3e56c6f2:/ansible$
    ```

10. Use the `ansible-playbook` command to launch the playbook, then enter the necessary variables when prompted
    ```sh
    ansible@2f9c3e56c6f2:/ansible$ ansible-playbook create_c2.yml 

    ```

11. If playbook runs successfully, you should see an output like this with no `failed` statuses
    ```sh
    ...
    PLAY RECAP ************************************************************************************************
    localhost: ok=9    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

    ansible@2f9c3e56c6f2:/ansible$
    ```

13. To update OS packages, update and license Cobalt Strke, and set up HTTP/HTTPS/DNS forwarding, run the `update_c2.yml` playbook. 

14. To remove all the C2 infrastructure you have created, run the `remove_c2.yml` playbook. 

# To Do: 

- [x] Automate entire C2 infrastructure setup
- [x] Create playbook to install and configure Cobalt Strike
- [x] Create playbook to decommission and terminate C2 infrastructure after an engagement
- [x] Edit usage instructions 
- [ ] Fix VPC deletion/dependency issues
- [ ] Figure out why AWS profiles don't seem to work

# Known Issues: 

### Availability zones and instances provisioning
Sometimes AWS won't provision the specified instance types in certain availability zones. Oddly enough, AWS also defaults to the `us-east-1e` availability zone, which almost always won't let us create `t2.small` or `t3.small` instances. Also, availability zone only needs to be set during `subnet` creation. As such, we've added the `availability_zone` variable. If you run into an issue like the example shown below, please try choosing a different availability zone (`us-east-1a`, `us-east-1b`, `us-east-1c`, `us-east-1d`, `us-east-1e`) are all valid options. 

Example:

    ```
    ... "error": {"code": "InsufficientInstanceCapacity", "message": "We currently do not have sufficient t3.small capacity in the Availability Zone you requested (us-east-1a). Our system will be working on provisioning additional capacity. You can currently get t3.small capacity by not specifying an Availability Zone in your request or choosing us-east-1b, us-east-1c, us-east-1d, us-east-1f."}
    ```

### VPC deletion
We currently can't automate the deletion of VPCs via Ansible playbooks, since if a VPC has a Route Table (RTB) attached, and that RTB is a "Main Route Table," then AWS requires manual input via the Mangement Console in order to delete the VPC and associated RTB. There's probably a workaround, but we haven't found it yet. You can run the `remove_c2.yml` playbook to delete most of the C2 infrastructure, but just be aware you'll need to go in and manually delete the VPC, RTB, and SGs. Tags still apply, so it's easy to track these down in the console. 

Example: 

    ```
    "error": {"code": "DependencyViolation", "message": "The vpc 'vpc-000e2b54fd15eb60a' has dependencies and cannot be deleted."}, "msg": "Failed to delete VPC vpc-000e2b54fd15eb60a You may want to use the ec2_vpc_subnet, ec2_vpc_igw, and/or ec2_vpc_route_table modules to ensure the other components are absent.
    ```

### AWS profiles
Yes, it's pretty annoying to have to change the first line of your `~/.aws/credentials` to `[default]`. One would assume we can set that to the standard `[my_user]` profile, but for some reason, this causes our playbooks to fail to authenticate. There's probably a workaround, but we haven't found it yet. 