This repository contains the [packer](http://packer.io/) configuration for creating the worker AMI from scratch. (The worker AMI is the image that runs the Docker container that runs the student submission.)

The `packer-worker.json` file contains the configuration for the AMI, including choosing the base image (currently Ubuntu 18.04) and specifying which script to run to set up the AMI. In this case, that script is `setup.sh`, which does a few things:
  1. Install packages.
  2. Install Docker and pull the latest Docker image.
  3. Save the GitHub key in the image so we can easily clone student work.
  4. Install the Autolab autodriver from the Tango repository.

Continuous deployment is set up for this repository on TravisCI. If you have been added to the GitHub organization and you navigate to <https://travis-ci.com>, you will see the build history for this repository. TravisCI initiates a build for this image each time you commit and push this repository to GitHub.

TravisCI needs to access our `AWS_ACCESS_KEY`, our `AWS_SECRET_KEY`, our `GITHUB_KEY`, our `DOCKER_USERNAME`, and our `DOCKER_PASSWORD`. To do this, we use [encryption](https://docs.travis-ci.com/user/encryption-keys/). In particular, you can run `travis encrypt AWS_ACCESS_KEY=... AWS_SECRET_KEY=... GITHUB_KEY=... DOCKER_USERNAME=... DOCKER_PASSWORD=... --add` (with the ellipses replaced by the value correponding to that key) to add the encrypted secret keys to the .travis.yml file.

To initiate an empty build (say, if you just updated the Docker image and you want to build a new AMI that has the latest version of the Docker image downloaded), you can make an empty commit with `git commit --allow-empty -m 'Trigger build of AMI with latest Docker image.'`.

The worker will be named in the format "15411\_worker\_TIMESTAMP.img", where TIMESTAMP is replaced with a TIMESTAMP of when the repo was built.

Manually building the AMI can be done with the following command:
```
AWS_ACCESS_KEY=... \
  AWS_SECRET_KEY=... \
  GITHUB_KEY=... \
  DOCKER_USERNAME=... \
  DOCKER_PASSWORD=... \
  packer build packer-worker.json
```
You should replace the ellipses `...` in each case with the appropriate secret values. Note that this command will actually create the image in the AWS organization.
