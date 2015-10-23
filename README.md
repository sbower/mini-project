mini-project
==============

Simple project to automate deployment of a web application

Prerequisites
============

It is assumed that firefox is installed for the cucumber tests.  You will need to have docker-machine installed, it is recommended to get the docker toolbox here: https://www.docker.com/docker-toolbox.  This script assumes that AWS credentials exist on the machine and does not provide a facility for passing them in, see http://docs.aws.amazon.com/AWSSdkDocsRuby/latest//DeveloperGuide/prog-basics-creds.html.  

Installation
============

1) install rvm

    $ \curl -L https://get.rvm.io | bash -s stable --ruby

2) install bundler

    $ gem install bundler

3) run bunlder to install required gems

    $ cd mini-project
    bundle install

Running Tests
=============

First you must build and run the container

1) Build Image

    docker build -t sbower/mini-project .

2) Run container from image

    docker run -d -p 80:80 sbower/mini-project

The simplest way to run a tests is with rake:

    rake HOST=http://docker_ip

You can run different profiles, for instance to run the wip profile

    rake cucumber:wip

The profiles are specified in config/cucumber.yml

Running Automated deployment
=============

The script requires two parameters to run, the subnet-id and vpc-id you wish to deploy to.  For example:

    ./create_and_deploy.rb --vpc-id vpc-6cdea409 --subnet-id subnet-6e22bc19

There is an option to skip the step that pushes to docker hub since folks wont have credentials to push to my repository, for example you could run:

    ./create_and_deploy.rb --vpc-id vpc-6cdea409 --subnet-id subnet-6e22bc19 --skip-images-push

Other possible solutions
=============

1) It seems like it would be pretty straightforward to just create a s3 bucket, drop the html file there and make it public.  See other/s3-website.sh.

2) Some of the work done in the script could be expressed in cloud formation such as creating the ec2 instance and the security group. See other/cf-mini-project.json.

3) Using ECS here wouldn’t be a huge stretch given the docker work is done.  It would be straightforward to create a cluster and attach a node and then convert the docker run into a task definition.

4) I could see where using Elastic Beanstalk would make sense, docker containers could be deployed there and Beanstalk takes care of the ELB and would make blue/green deployment easy.
