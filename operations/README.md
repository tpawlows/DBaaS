# Operations

Instructions and necessary data to do cluster operations like:
- scale out
- scale in
- scale up
- scale down
- version upgrade
- backup

## Tools
- kops
- pgo
- kubectl

## Day-2 Operations
All operations presented in this section are examples with assumption, that you:
- deployed Postgres Cluster on 2 or 3 nodes
- all postgres cluster resources (without Operator) are deployed on dedicated instances
- rest of the services (monitoring, dasboards, ingress, external-dns, etc.) are deployed on different nodes

# Scale out
*Scaling out application means to add another instance of an application to the existing group*
```bash
kops create -f operations/instance-groups/2-instances-t3.large.yaml
kops update cluster --yes
kops rolling-update cluster --yes
# Add one replica to Postgres Cluuster
pgo scale hippo --replica-count=1 --no-prompt
```

# Scale in
*Scaling in application means to remove one instance of an application from the existing group*
```bash
# Remove node from Postgres Cluster
kops replace -f operations/instance-groups/1-instances-t3.medium.yaml
kops update cluster --yes
kops rolling-update cluster --yes
# Remove one replica from Postgres Cluuster
pgo scaledown hippo --no-prompt --query | tail -n1 | awk '{print $1}' | xargs pgo scaledown hippo --no-prompt --target
```

# Scale up
*Scaling up application means to move application from a machine with lower compute resources to the one with more resources*
```bash
# Create Postgres Cluster with 1 primary and 2 replica on t3.medium instance each
# Create instance group with t3.large instances
kops create -f operations/instance-groups/hippo-large.yaml 
kops update cluster --yes
kops rolling-update cluster --yes
# move postgres cluster from medium to large instances
pgo update cluster hippo  --toleration=dedicated=hippo-cluster:NoSchedule- --toleration=dedicated=large-cluster:NoSchedule
```

# Scale down

*Scaling down application means to move application from a machine with higher compute resources to the one with less resources*
```bash
# Move scaled up instances from t3.large back to t3.medium
pgo update cluster hippo  --toleration=dedicated=hippo-cluster:NoSchedule --toleration=dedicated=large-cluster:NoSchedule-
```
# Version upgrade

*Version upgrade means to replace container with postgres database from an older one to new one*
```bash
# Assuming that postgres cluster is deployed with centos8-13.3-4.7.0
# update deployed postgres cluster to the new version
pgo upgrade --ccp-image-tag centos8-13.4-4.7.2  --no-prompt hippo
```

# Backup

*Backup is a copy of computer data taken and stored elsewhere so that it may be used to restore the original after a data loss event. *
```bash
# perform a backup and store data on a disk
pgo backup hippo
```
