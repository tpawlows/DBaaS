# kops-create-cluster

Use KOPS for creating k8s cluster on AWS.

# Prerequisites

I assume that you have machine with Ubuntu 20.04 (I use WSL 2 on Windows 10).

- Run update and upgrade on your local machine.
	```bash
	sudo apt-get -y update && apt-get -y upgrade
	```
- Install required packages
	- kubectl
	```bash
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
	```
	- awscli
	```bash
	sudo apt-get install awscli
	```
	- kops
	```bash
	curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
	chmod +x kops-linux-amd64
	sudo mv kops-linux-amd64 /usr/local/bin/kops
	```
- Create **kops** user on AWS with permissions listed below.
	 ```bash
	AmazonEC2FullAccess
	IAMFullAccess
	AmazonS3FullAccess
	AmazonVPCFullAccess
	Route53FullAccess
	 ```
- Configure **kops** user on your local machine
	- provide **aws_access_key** and **aws_secret_key**
	- choose aws region (in my case eu-north-1)
	 ```bash
	aws configure
	```
- Create rsa ssh key for connecting to kubernetes/bastion instances.
	```bash
	ssh-keygen
	```
- Create s3 bucket
	```bash
	aws s3api create-bucket --bucket $BUCKET \
		--region $REGION \
		--create-bucket-configuration LocationConstraint=$REGION 
		--acl private
	aws s3api put-public-access-block --bucket $BUCKET \
		--public-access-block-configuration \
	BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
	```
- Create DNS public hosted zone
	- I also use my own, bought domain, which I am going to use with my hosted zone. It's not necessary, but I recommend it for better experience (in that case I name hosted zone the same as my domain)
	- creating private hosted zone needs some VPC associated, so we provide default in $REGION.
	```bash
	aws route53 create-hosted-zone --name $DNS_ZONE  \
	--caller-reference 1 --vpc=VPCRegion=$REGION,VPCId=$DEFAULT_VPC_ID
	```
- Export **aws_access_key**, **aws_secret_key** and  KOPS_STATE_STORE as Env variables for kops
	- You can add them to ~/.bashrc, so you don't have to export them in the future
	```bash
	export aws_access_key_id=$(grep aws_access_key_id ~/.aws/credentials | awk '{print $3}')
	export aws_secret_access_key=$(grep aws_secret_access_key ~/.aws/credentials | awk '{print $3}')
	export KOPS_STATE_STORE=$BUCKET
	```
- Everything is now ready for creating a kubernetes cluster in AWS.

# Usage

To create **default** cluster configuration simply run command.
```bash
kops create cluster --name $CLUSTER \
	--zones=$ZONE \
	--dns-zone $DNS_ZONE
```
It will create a cluster configuration and store it in a as3 bucket.
To actually **create** a cluster run:
```bash
kops update cluster $CLUSTER --yes
```
I recommend running command below to avoid getting problems with kubectl and kops validate described 
[here](https://stackoverflow.com/questions/66341494/kops-1-19-reports-error-unauthorized-when-interfacing-with-aws-cluster)
```bash
kops export kubecfg --admin
```
To delete cluster and configuration run:
```bash
kops delete cluster $CLUSTER --yes
```
To create configuration files without creating cluster or saving configuration to s3, simply add parameters **--dry-run** and **--output yaml**
```bash
kops create cluster --name $CLUSTER \
	--zones=$ZONE \
	--dns-zone $DNS_ZONE \
	--dry-run --output yaml > cluster.yaml
```
You can view and modify file as you like.
To create cluster from a previously generated files run:
```bash
kops create -f cluster.yaml
# Need to store ssh public key as a KOPS secret, before deploying cluster created from a configuration file
kops create secret --name $CLUSTER sshpublickey admin -i ~/.ssh/id_rsa.pub
kops update cluster $CLUSTER --yes
# Reload kubecfg
kops export kubecfg --admin
```