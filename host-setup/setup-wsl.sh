#!/bin/bash

USER=$whoami
cd ~

sudo apt-get -y update
sudo apt-get -y upgrade

# passwordless https AUTH w/ github repositories
cat > .netrc << EOL
machine github.com
    login tpawlows
    password $(cat .dbaas.configuration | grep gh_pat | cut -d \" -f2) 
EOL
chmod 600 .netrc

# passwordless sudo
sudo echo "retipuj ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo

# install core packages
sudo apt-get -y install git unzip wget curl postgresql-client postgresql-contrib

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
echo 'source <(kubectl completion bash)' >>~/.bashrc

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# install kops
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# configure awscli
aws_access_key=$(cat .dbaas.configuration | grep aws_access_key | cut -d \" -f2)
aws_secret_key=$(c)
aws_region="eu-north-1"
aws_format="json"
echo -e "${aws_access_key}\n${aws_secret_key}\n${aws_region}\n${aws_format}" | aws configure

# install pgo-client
curl https://raw.githubusercontent.com/CrunchyData/postgres-operator/v4.7.3/installers/kubectl/client-setup.sh > client-setup.sh
chmod +x client-setup.sh
./client-setup.sh

# add enviroment variables for pgo
cat <<EOF >> ~/.bashrc
# PGO
export PGOUSER="${HOME?}/.pgo/pgo/pgouser"
export PGO_CA_CERT="${HOME?}/.pgo/pgo/client.crt"
export PGO_CLIENT_CERT="${HOME?}/.pgo/pgo/client.crt"
export PGO_CLIENT_KEY="${HOME?}/.pgo/pgo/client.key"
export PGO_APISERVER_URL='https://pgo.k8s.retipuj.com:8443'
export PGO_NAMESPACE=pgo
EOF

# Postgres environment variables
cat <<EOF >> ~/.bashrc
# Postgres
export PGHOST="https://hippo.k8s.retipuj.com"
export PGPORT=9187
export PGDATABASE="hippo"
export PGUSER="pguser"
export PGPASSWORD=$(cat .dbaas.configuration | grep pg_password | cut -d \" -f2)
EOF

# set grafana password
cat <<EOF >> ~/.bashrc
# Grafana
export GRAFANA_PASSWORD=$(cat .dbaas.configuration | grep grafana_password | cut -d \" -f2)
EOF

# apply changes from ~/.bashrc
source ~/.bashrc

# cleanup
rm awscliv2.zip get_helm.sh kubectl.sha256 client-setup.sh kubectl
