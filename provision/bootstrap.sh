#!/usr/bin/env bash

# This script should:
#
# - Set a system wide package proxy if needed
# - Make sure ruby is installed
# - make sure puppet is installed
# - make sure a role has been set from somewhere:
#   - DNS
#   - hostname
#   - ???
# - make sure the fqdn is set and working
#
proxy="${proxy:-}"
desired_puppet=3.7.3

date

while getopts "h?p:" opt; do
    case "$opt" in
    h|\?)
        echo "Not helpful help message"
        exit 0
        ;;
    p)  proxy=$OPTARG
        ;;
    esac
done

# Get vagrant seed data into config drive
if mount | grep -q vagrant; then
  mkdir -p /mnt/config/openstack/latest
  ruby -ryaml -rjson -e 'puts JSON.pretty_generate({ :meta => YAML.load(ARGF)})' < /tmp/cloudinit.yaml > /mnt/config/openstack/latest/meta_data.json
fi

# This might be a cloud instance. Grab config data if so.
# Try config drive first
if [ -e /dev/disk/by-label/config-2 ]; then
    if [ ! -d /mnt/config ]; then
      mkdir -p /mnt/config
      mount /dev/disk/by-label/config-2 /mnt/config
    fi
fi

if mount | grep -q vagrant; then
    echo 'Vagrant host detected via mount, not configuring network'
else
    for i in `ip -o link show | grep eth[1-9] | cut -d ':' -f 2`; do
        if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]; then
            cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-$i
            sed -i "s/eth0/$i/g" /etc/sysconfig/network-scripts/ifcfg-$i
        fi
        ethtool -K $i tso off
        ethtool -K $i gro off
        ethtool -K $i gso off
        ifconfig $i down
        ifconfig $i up
    done

    # not working yet
    for i in `ip -o link show | grep enp[[:digit:]] | cut -d ':' -f 2`; do
        ethtool -K $i tso off
        ethtool -K $i gro off
        ethtool -K $i gso off
        ifconfig $i up
    done

    if ip -o link show | grep eth[1-9] ; then
        ethtool -K eth0 tso off
        ethtool -K eth0 gro off
        ethtool -K eth0 gso off
        dhclient `ip -o link show | grep eth[1-9] | cut -d ':' -f 2 | tr '\n' ' '`
        dhclient eth0
    fi

    if ip -o link show | grep enp[[:digit:]]  ; then
        dhclient `ip -o link show | grep eth[1-9] | cut -d ':' -f 2 | tr '\n' ' '`
    fi
fi

# Set either yum or apt to use an http proxy.
if [ $proxy ] ; then
    echo 'setting proxy'

    if [ -f /etc/redhat-release ] ; then
        if [ ! $(cat /etc/yum.conf | grep '^proxy=') ] ; then
            echo "proxy=$proxy" >> /etc/yum.conf
        fi
    elif [ -f /etc/debian_version ] ; then
        if [ ! -f /etc/apt/apt.conf.d/01apt-cacher-ng-proxy ] ; then
            echo "Acquire::http { Proxy \"$proxy\"; };" > /etc/apt/apt.conf.d/01apt-cacher-ng-proxy;
            apt-get update -q
        fi
    else
        echo "OS not detected for proxy settings! Weirdness inbound!"
    fi
else
    echo 'not setting proxy'
fi


mirror_address=None
if [ -f /mnt/config/openstack/latest/meta_data.json ]; then
    mirror_address=`cat /mnt/config/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('mirror_address', None)"`
elif curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json &> /dev/null; then
    mirror_address=`curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('mirror_address', None)"`
fi
if mount | grep -q vagrant; then
    if [ "$(hostname | grep -oh '^[[:alpha:]]*')" = "build" ] ; then
        mirror_address="None"
    else
        mirror_address="192.168.242.5"
    fi
fi

# Mirror nodes need to pull in the PL repo to get started along
# with the aptira mirror for the 'ts' rpm
# Whereas others should use the local mirror for all packages
if [ "${mirror_address}" = "None" ] ; then
    echo '[puppetlabs]' > /etc/yum.repos.d/puppetlabs.repo
    echo "name=Puppetlabs Yum Repo" >> /etc/yum.repos.d/puppetlabs.repo
    echo "baseurl=\"http://yum.puppetlabs.com/el/\$releasever/products/\$basearch/\"" >> /etc/yum.repos.d/puppetlabs.repo
    echo 'enabled=1' >> /etc/yum.repos.d/puppetlabs.repo
    echo 'gpgcheck=1' >> /etc/yum.repos.d/puppetlabs.repo
    echo 'gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs' >> /etc/yum.repos.d/puppetlabs.repo

    echo '[aptira]' > /etc/yum.repos.d/aptira.repo
    echo "name=Consul Packages hosted at Aptira" >> /etc/yum.repos.d/aptira.repo
    echo "baseurl=\"http://stacktira.aptira.com/repo/consul\"" >> /etc/yum.repos.d/aptira.repo
    echo 'enabled=1' >> /etc/yum.repos.d/aptira.repo
    echo 'gpgcheck=0' >> /etc/yum.repos.d/aptira.repo

    echo '[puppetlabs-deps]' > /etc/yum.repos.d/puppetlabs-deps.repo
    echo "name=Puppetlabs Dependencies Yum Repo" >> /etc/yum.repos.d/puppetlabs-deps.repo
    echo "baseurl=\"http://yum.puppetlabs.com/el/\$releasever/dependencies/\$basearch/\"" >> /etc/yum.repos.d/puppetlabs-deps.repo
    echo 'enabled=1' >> /etc/yum.repos.d/puppetlabs-deps.repo
    echo 'gpgcheck=1' >> /etc/yum.repos.d/puppetlabs-deps.repo
    echo 'gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs' >> /etc/yum.repos.d/puppetlabs-deps.repo
else
    rm -f `find /etc/yum.repos.d/*.repo | grep -v local.repo`
    echo '[local]' > /etc/yum.repos.d/local.repo
    echo "name=Local Mirror" >> /etc/yum.repos.d/local.repo
    echo "baseurl=http://$mirror_address/" >> /etc/yum.repos.d/local.repo
    echo 'enabled=1' >> /etc/yum.repos.d/local.repo
    echo 'gpgcheck=0' >> /etc/yum.repos.d/local.repo
fi

yum update -y

# Install facter so we can find interfaces easily
if ! yum list installed facter > /dev/null 2>&1; then
    yum install -y facter
fi

mkdir -p /etc/facter/facts.d
# Lock network facts to prevent bridge malarky and VIPs from doing strange things
if ! [ -f /etc/facter/facts.d/ipaddress.yaml ]; then
    # Do in 2 phases due to odd 'could not interpret fact file' bug
    facter | grep ipaddress | sed 's/\ =>/:/' > /tmp/out.yaml
    mv -f /tmp/out.yaml /etc/facter/facts.d/ipaddress.yaml
fi
date

# get role
role=None
if [ -f /mnt/config/openstack/latest/meta_data.json ]; then
    role=`cat /mnt/config/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('role', None)"`
elif curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json &> /dev/null; then
    role=`curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('role', None)"`
fi
if [ "${role}" = "None" ] ; then
  role=`hostname | grep -oh '^[[:alpha:]]*'`
fi

# Set role fact
mkdir -p /etc/facter/facts.d
echo "role: $role" > /etc/facter/facts.d/role.yaml

# get provisioner
provisioner=None
if [ -f /mnt/config/openstack/latest/meta_data.json ]; then
    provisioner=`cat /mnt/config/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('provisioner', None)"`
elif curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json &> /dev/null; then
    provisioner=`curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('provisioner', None)"`
fi
if [ "${provisioner}" = "None" ] ; then
    provisioner=puppet
fi

if [ "${role}" != "build" ] ; then
# Install and configure consul
  bash -x /vagrant/provision/consul.sh
fi

if [ -f /vagrant/provision/$role ] ; then
  bash -x /vagrant/provision/${role}.sh
else
  bash -x /vagrant/provision/${provisioner}.sh
fi
