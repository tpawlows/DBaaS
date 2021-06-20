#!/bin/bash

kops create cluster \
	--name=$1 \
	--cloud=aws \
	--zones="eu-north-1a" \
	--dns-zone=$2 \
	--node-count=1 \
	--master-volume-size=32 \
	--node-volume-size=32 \
	--topology=private \
	--networking=kube-router 
	