#!/bin/bash -e

tango_repo="15-411/Tango"

logit () {
   echo "***SUMMARY*** $1"
   echo "$1" >> ~/.image-setup-summary.log
}
logit 'Script starting.'

sleep_time=120
if [ ! -z "$sleep_time" ]; then
  logit "Sleeping for $sleep_time seconds to allow for sufficient setup for Ubuntu..."
  sleep $sleep_time
fi

logit 'Validating environment...'
if [ -z "$DOCKER_PASSWORD" ]; then
  echo "./setup.sh: Empty docker password."
  echo "./setup.sh: Exiting..."
  exit 1
fi

if [ -z "$DOCKER_USERNAME" ]; then
  echo "./setup.sh: Empty docker username."
  echo "./setup.sh: Exiting..."
  exit 1
fi

logit 'Installing necessary software...'
sudo apt-get update
sudo apt-get install -y \
  gcc \
  make \
  python \
  python3 \
  ;

logit 'Creating users...'
sudo useradd -c 'Autograder account' -U -m -s /bin/bash autograde
sudo usermod -a -G autograde ubuntu
# reload groups; see https://superuser.com/a/345051
newgrp autograde
newgrp ubuntu

logit 'Installing Docker...'
curl -sSL https://get.docker.com/ | sudo sh
# Give autograde user the ability to use and manage docker.
sudo usermod -aG docker autograde
# Authenticate with secret credentials.
sudo docker login --password "$DOCKER_PASSWORD" --username "$DOCKER_USERNAME"
sudo docker pull cmu411/autograder:latest

logit 'Trusting GitHub ssh keys...'
ssh-keyscan github.com |
  sudo tee -a /root/.ssh/known_hosts |
  sudo tee -a ~ubuntu/.ssh/known_hosts

logit 'Cloning Tango and installing autodriver...'
chmod 400 "$GITHUB_PEM"
ssh-agent bash -c "ssh-add $GITHUB_PEM ; git clone git@github.com:$tango_repo.git Tango"
make -C Tango/autodriver
sudo make -C Tango/autodriver install
rm -rf Tango

logit 'Done'
