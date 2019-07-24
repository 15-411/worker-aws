#!/bin/bash -e

tango_repo="15-411/Tango"
static_analysis_repo="15-411/static-analysis"
container="building_static_analysis"

logit () {
   echo "***SUMMARY*** $1"
   echo "$1" >> ~/.image-setup-summary.log
}
logit 'Script starting.'

sleep_time=120
if [ ! -z "$sleep_time" ]; then
  logit "Sleeping for $sleep_time seconds to allow for sufficient setup for Ubuntu..."
  sleep "$sleep_time"
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

if [ -z "$GITHUB_PEM" ]; then
  echo "./setup.sh: Empty GITHUB_PEM environment variable."
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

# Cache all necessary images
for l in ocaml haskell sml rust other; do
  sudo docker pull "cmu411/autograder-$l:latest"
done

logit 'Trusting GitHub ssh keys...'
ssh-keyscan github.com |
  sudo tee -a /root/.ssh/known_hosts |
  tee -a ~ubuntu/.ssh/known_hosts

logit 'Cloning Tango and installing autodriver...'
chmod 400 "$GITHUB_PEM"
ssh-agent bash -c "ssh-add $GITHUB_PEM ; git clone git@github.com:$tango_repo.git Tango"
make -C Tango/autodriver
sudo make -C Tango/autodriver install
rm -rf Tango

logit 'Building static analysis tools on Docker...'
ssh-agent bash -c "ssh-add $GITHUB_PEM; git clone -q git@github.com:$static_analysis_repo.git static-analysis"
rm -rf static-analysis/.git

sudo docker run --name "$container" -td cmu411/autograder-ocaml:latest
sudo docker cp static-analysis "$container:/autograder/static-analysis"
rm -rf static-analysis

# Make the static analysis binaries on the Docker container.
# (The PS1 nonsense is for reasons that follow:
# The .bashrc checks if PS1 is set to something before allowing us
# to source. We are fooling the .bashrc into thinking we're an
# interactive shell. We need stuff in the bashrc.)
sudo docker exec "$container" bash -c "PS1=a ; source ~/.bashrc ; make -C static-analysis"
sudo docker cp "$container:/autograder/static-analysis" static-analysis
sudo docker stop "$container"
sudo docker rm "$container"

logit 'Done'
