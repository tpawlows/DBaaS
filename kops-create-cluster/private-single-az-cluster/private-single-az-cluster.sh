#!/bin/bash
# arguments:
# cluster_name hosted_zone availability_zones
echo "Cluster name:			${1:-k8s.retipuj.com}"
echo "Hosted Zone:			${2:-retipuj.com}"
echo "Availability Zones:		${3:-eu-north-1a}"

# Create and save configuration to s3
kops create cluster \
	--name=${1:-k8s.retipuj.com} \
	--dns-zone=${2:-retipuj.com} \
	--zones=${3:-eu-north-1a} \
	--cloud=aws \
	--node-count=1 \
	--master-volume-size=32 \
	--node-volume-size=32 \
	--topology=private \
	--networking=kube-router 
echo "Cluster configuration saved to: $KOPS_STATE_STORE"

# Create actual cluster on AWS
kops update cluster ${1:-k8s.retipuj.com} --yes --admin

# Wait for kOps to create cluster (about 12 min) 
kops validate cluster --wait 15m