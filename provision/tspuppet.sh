puppet apply /etc/puppet/manifests/site.pp --detailed-exitcodes ;
if (($? != 1 && $? != 4 && $? != 6)) ; then
  exit 0
else
  ts /vagrant/provision/tspuppet.sh
fi;
