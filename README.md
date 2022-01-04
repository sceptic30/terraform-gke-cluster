# Google Kubernetes Cluster Autoprovisioning

This project autoprovisioning a full regional cluster in Google Kubernetes Engine, while using Longhorn clustering mechanism to cluster 3 Persistent Disks across 3 different zones, ensuring Fault Tolerance and High Availability.

A bash script lifting the weight of creating the appropriate commands by creating persistent disks in each zone, and automatically attaching these disks to each Kubernetes Node, while Ansible takes care of mounting the disks to a specified location at each node. After all revelant installations finish, you will be promped via command line to create a Username and a Password for securing the UI of Longhorn and Netdata, and will be submitted to Kubernetes API as secrets.

Lastly, your kubernetes nodes will be automatically claimed, and you will have immediate access to all metrics.

## Programming Language Used

1. Bash

## DevOps Tooling Used

1. Terraform (*Infrastructure Provisioning Tool*)
2. Ansible (*Configuration Management Tool*)
3. Jenkins (*Continuous Integration - Continuous Deployment Automation Server*)
4. NetData (*Health Monitoring - Observability Tool*)

## In-Cluster Technologies Used

There is a number of technologies used such as:

1. CertManager
2. External-DNS
3. Haproxy Ingress Controller
4. Longhorn Distrubuted Storage Platform
5. Nginx

## Usage

First, download clone the repository, and give to install.sh and initiate.sh the appropriate permissions `chmod a+x` and generate and public-private key pair as exactly show below:

```bash
git clone https://github.com/sceptic30/terraform-gke-cluster.git
cd terraform-gke-cluster
chmod a+x install.sh initiate.sh
mkdir -p keys
ssh-keygen -t ed25519 -f ./keys/root_id_ed25519
```

The private-public key pair will be used by Ansible, as it's necessary to configure the Docker Daemon systemd service.
Then, edit the following variables in *initiate.sh*:

```bash
export BASE_DOMAIN=your_domain_name
export NETDATA_TOKEN=your_netdata_token
export NETDATA_ROOMS=your-netdata-rooms
export CLUSTER_ADMIN_EMAIL=your_google_mail_address
```

And run the installation script:

```bash
source initiate.sh
```

## Demo

Watch the whole process of provisioning in the [Demo Video](https://www.youtube.com/watch?v=0KWD3peHjfw "Provisioning a Google Kunernetes Cluster") on Youtube.

## Cluster Requirements

The recommended cpu-memory requirements is 4 cores with 4Gb of RAM per node.
