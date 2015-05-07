puppet apply /etc/puppet/manifests/site.pp --detailed-exitcodes >> /root/bootstrap.log;
if (($? != 1 && $? != 4 && $? != 6)) ; then
  exit 0
else
  sleep 10;
  ts /vagrant/provision/tspuppet.sh
fi;
