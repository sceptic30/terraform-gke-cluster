# Google Kubernetes Cluster Autoprovisioning

This project autoprovisioning a full regional cluster in Google Kubernetes Engine, while using Longhorn clustering mechanism to cluster 3 Persistent Disks across 3 different zones, ensuring Fault Tolerance and High Availability.

A bash script lifting the weight of creating the appropriate commands by creating persistent disks in each zone, and automatically attaching these disks to each Kubernetes Node, while Ansible takes care of mounting the disks to a specified location at each node. After all revelant installations finish, you will be promped via command line to create a Username and a Password for securing the UI of Longhorn and Netdata, and will be submitted to Kubernetes API as secrets.

Lastly, your kubernetes nodes will be automatically claimed, and you will have immediate access to all metrics.
## Programming Language Used
1. <ins>Bash</ins>
## DevOps Tooling Used
1. <ins>Terraform</ins> (*Infrastructure Provisioning Tool*)
2. <ins>Ansible</ins> (*Configuration Management Tool*)
3. <ins>Jenkins</ins> (*Continuous Integration- Continuous Deployment Automation Server*)
4. <ins>NetData</ins> (*Health Monitoring - Observability Tool*)

## In-Cluster Technologies Used

There is a number of technologies used such as:
1. <ins>CertManager</ins>
2. <ins>External-DNS</ins>
3. <ins>Haproxy Ingress Controller</ins>
4. <ins>Longhorn Distrubuted Storage Platform</ins>
5. <ins>Nginx</ins>

## Usage
First, download clone the repository, and give to install.sh and initiate.sh the appropriate permissions `chmod a+x` and generate and public-private key pair as exactly show below:

```
git clone https://github.com/sceptic30/terraform-gke-cluster.git
cd terraform-gke-cluster
chmod a+x install.sh initiate.sh
mkdir -p keys
ssh-keygen -t ed25519 -f ./keys/root_id_ed25519
```
The private-public key pair will be used by Ansible, as it's necessary to configure the Docker Daemon systemd service.
Then, edit the following variables in *initiate.sh*:
```
export BASE_DOMAIN=your_domain_name
export NETDATA_TOKEN=your_netdata_token
export NETDATA_ROOMS=your-netdata-rooms
export CLUSTER_ADMIN_EMAIL=your_google_mail_address
```
And run the installation script:
```
source initiate.sh
```

## Cluster Requirements
The recommended cpu-memory requirements is 4 cores with 4Gb of Ram per node.