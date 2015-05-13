Stacktira
================

This is an experimental devops platform, currently used to deploy the latest release of OpenStack.

## Components

At its core, stacktira is the following:

 * a set of heat templates+Vagrantfile to provision virtual environments
 * a bootstrap script that will prepare nodes
 * a list of git repositories to clone
 * a list of providers to provision a node using the git repos

In addition, there is the concept of a build node that will pull down a mirror of the required packages for a given
environment so that all other nodes can:

 * share a local mirror
 * control package versions across the cluster
 * manage updates
 * deploy without internet access (not really since we still need git atm!)

## Strategy

The general structure of the system is that consul sits at the centre, providing a service registry, cluster membership and a key
value store, while puppet is used to consume this data via hiera-consul and also to publish using puppet-orchestration\_utils. There is no
need for a puppet master, since consul is providing node kicks and data. A small tool called `ts` is used to wrap all the puppet apply runs
so that we can register watches in consul to trigger changes on nodes without running multiple copies of puppet at the same time. The result
is a system that moves towards not just being automated, but being autonomous, as we can capture the appropriate responses to changes in data
in puppet, and trigger them via watches. A preliminary example of this is provided by the haproxy classes in the `consul_profile` module.

Additionally, we sidestep many of the limitations in puppet. We remove the need for master and slave roles for the case of deploying distributed
systems that need to be bootstrapped or have other limitations by using consul's leader election services to choose one of the candidate nodes
and querying it from hiera. We gain the ability to deploy resources in cross node order by querying consul to see if required data is available and
either waiting or erroring and re-running puppet if it's not. Finally, we do all of this without a puppet master or any requirement for certificate
configuration, greatly reducing the bootstrapping complexity.

## Launching an Environment

Virtual environments can be easily created using either heat or vagrant:

### Heat

To launch using heat, deploy the mirror by using the heat/mirror.yaml template, against an icehouse or newer cloud like so:

    heat stack-create -f heat/mirror.yaml my_mirror

you will need to specify parameters like what flavor and public network to use. We have a sample environment file available for one of the Cisco clouds, whcih would be used like this:

    heat stack-create -f heat/mirror.yaml -e heat/environments/integration.yaml my_mirror

Otherwise you can pass in parameters using -P

    heat stack-create -f heat/mirror.yaml -P pubnet=public_floating_600 -P small_flavor=m1.small my_mirror

Then you can create an environment using that mirror by using:

    heat stack-create -f heat/3role.yaml -P mirror_address=[the floating IP from the previous stack] ... my_env

### Vagrant

First, you should clone all the repositories locally using:

   ./provision/cloner repos.yaml

Then to create the build node, use

    vagrant up build1

Then you can deploy all the other nodes concurrently using:

    bash tests/vagrant.sh

This will require a lot of RAM! (>16GB)
