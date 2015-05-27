yum install git puppet hiera python-yaml -y -q

# Install ts for queuing puppet runs
if ! yum list installed ts > /dev/null 2>&1; then
    yum install -y ts
fi

if [ ! -d /etc/puppet/hiera/data ]; then
    mkdir -p /etc/puppet/hiera/data
fi

configure_dir=/vagrant
cp $configure_dir/hiera/hiera.yaml /etc/puppet
cp $configure_dir/hiera/hiera.yaml /etc

rm -rf /etc/puppet/hiera/data
cp -r $configure_dir/hiera/data /etc/puppet/hiera

rm -rf /etc/puppet/manifests
cp -r $configure_dir/manifests /etc/puppet

# This will be 'virtualbox' on osx vagrant systems
productname=$(facter productname)
if [ "$productname" != "VirtualBox" ]; then
  # Use config drive if it's there
  if [ -e /dev/disk/by-label/config-2 ]; then
      python -c "import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin)['meta'], sys.stdout, default_flow_style=False)" < /mnt/config/openstack/latest/meta_data.json > /etc/puppet/hiera/data/cloudinit.yaml
  # Otherwise use metadata service
  else
      curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin)['meta'], sys.stdout, default_flow_style=False)" > /etc/puppet/hiera/data/cloudinit.yaml
  fi
fi

mkdir -p /vagrant/vendor
mkdir -p /vagrant/modules
# Use cloner (exp)
cd /vagrant
if [ "$productname" != "VirtualBox" ]; then
  ./provision/cloner repos.yaml
fi
date
# Install puppet modules
rm -rf /etc/puppet/modules/*
mkdir -p /etc/puppet/modules
cp -r modules/* /etc/puppet/modules

# Ensure puppet isn't going to sign a cert with the wrong time or
# name
domain=$(hiera domain)
fqdn_iface=$(hiera mgmt_iface)
ipaddress=$(facter ipaddress_$fqdn_iface)
fqdn=$(facter hostname).${domain}
facter_fqdn=$(facter fqdn)
# If it doesn't match what puppet will be setting for fqdn, just redo
# to the point where we can see the master and have fqdn
if [ "${facter_fqdn}" != "${fqdn}" ] ; then
  if ! grep -q "$ipaddress\s$fqdn" /etc/hosts ; then
    echo 'configuring /etc/hosts for fqdn'
    if [ -f /etc/redhat-release ] ; then
        echo "$ipaddress $fqdn $(hostname)" > /etc/hosts
        echo "127.0.0.1       localhost       localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts
        echo "::1     localhost       localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
    elif [ -f /etc/debian_version ] ; then
        echo "$ipaddress $fqdn $(hostname)" > /etc/hosts
        echo "127.0.0.1       localhost       localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts
        echo "::1     localhost       localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
    fi
  fi
fi

cronentry='*/2 * * * * root /vagrant/provision/tspuppet.sh'
echo "$cronentry" > /etc/cron.d/tspuppet
