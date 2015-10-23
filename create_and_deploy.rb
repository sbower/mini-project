#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'base64'
require 'os'

DEMARK = "*" * 25
MINI_PROJECT_SECURITY_GROUP = "mini-project-sg"

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: create_and_deploy.rb [options]"

  opts.on('--skip-images-push', 'Skip pushing docker image to docker hub') { |v| options[:skip_image_push] = v }
  opts.on('--subnet-id SUBNET-ID', 'ID of the subnet to launch the instance into') { |v| options[:subnet_id] = v }
  opts.on('--vpc-id VPC-ID', 'ID of the subnet to launch the instance into') { |v| options[:vpc_id] = v }


  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

def check_machine_active?
    @machine = `docker-machine active`
    @machine.empty?
end

def get_machine_ip
  `docker-machine ip #{@machine}`.chop
end

def build_docker_image
  puts "building docker image"
  puts `docker build -t 'sbower/mini-project' .`
  puts DEMARK
end

def run_test_image
  puts "running docker images"
  container =  `docker run -d -p 80:80 sbower/mini-project`

  puts "running test"
  puts "bundle exec cucumber HOST=http://#{get_machine_ip} --format pretty --profile default"

  puts `bundle exec cucumber HOST=http://#{get_machine_ip} --format pretty --profile default`
  retval = $?.exitstatus
  puts "cleaning up container"
  `docker stop #{container}`
  `docker rm #{container}`

  puts DEMARK
  retval
end

def push_image_to_docker_hub
  puts "pushing image to hub.docker.com"
  puts `docker push sbower/mini-project`

  puts DEMARK
  $?.exitstatus
end

def create_security_group
  puts "creating security group"
  group_id = ""
  resp = @ec2.describe_security_groups(filters: [
    {
      name: "group-name",
      values: [MINI_PROJECT_SECURITY_GROUP],
    }])
  if resp.security_groups.empty?
    resp = @ec2.create_security_group(group_name: MINI_PROJECT_SECURITY_GROUP,
                                      description: MINI_PROJECT_SECURITY_GROUP,
                                      vpc_id: @vpc_id)

    group_id = resp.group_id
    sg = Aws::EC2::SecurityGroup.new(group_id, {client: @ec2})
    sg.authorize_ingress(ip_protocol: "tcp",
                          from_port: 80,
                          to_port: 80,
                          cidr_ip: "0.0.0.0/0")
  else
    group_id = resp.security_groups[0].group_id
  end
  puts "using mini-project-sg #{group_id}"
  puts DEMARK

  group_id
end

def create_ec2_instance(sg_id)
  puts "creating ec2 instance"

  # start new instance using a an ami for ECS optomized linux
  # so we will already have docker installed
  resp = @ec2.run_instances(image_id: "ami-4fe4852a",
                            min_count: 1,
                            max_count: 1,
                            instance_type: "t2.micro",
                            #iam_instance_profile: iam_instance_profile,
                            user_data: Base64.encode64("#!/bin/sh \n\ndocker run -d -p 80:80 sbower/mini-project"),
                            subnet_id: @subnet_id,
                            security_group_ids: [sg_id])

  instance_id = resp.instances[0].instance_id
  puts "#{instance_id} is booting"

  mini_project = Aws::EC2::Instance.new(instance_id, {client: @ec2})
  mini_project.wait_until_running
  puts DEMARK

  "http://#{mini_project.public_dns_name}"
end

# There must be an active docker machine so we can build the image
if check_machine_active?
  puts "You must have an active machine selected with docker-machine"
  exit 1
end

# check required parameters
if !options[:vpc_id] || !options[:subnet_id]
  puts "vpc-id is a required parameter"
  puts "subnet-id is a required parameter"
  exit 1
end

# captures these parameters globally
@vpc_id = options[:vpc_id]
@subnet_id = options[:subnet_id]

# create ec2 client object
@ec2 = Aws::EC2::Client.new({region: "us-east-1"})

#build the docker images
build_docker_image

# use the image to run a container
# run cucmber test against that container
if run_test_image != 0
  puts "Test did not pass, aborting"
  exit 1
end

# pushe the image to docker hub
# allow this step to be skipped since it is pushing to my repo
push_image_to_docker_hub unless options[:skip_image_push]

# create mini-project-sg which allows all tcp traffic on 80
sg_id = create_security_group

# create ec2 instance to run the container
public_dns_name = create_ec2_instance(sg_id)

# put in a sleep to allow cloud-init to finish and the container to start
puts "nap while waiting for cloud-init"
sleep 120
puts DEMARK

# if we are on a mac launch the site in the default browser otherwise display the public dns
if OS.mac?
  `open #{public_dns_name}`
else
  puts "site runnung at #{public_dns_name}"
end
