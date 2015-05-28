date >> /root/bootstrap.log
puppet apply /etc/puppet/manifests/site.pp --detailed-exitcodes >> /root/bootstrap.log;
if (($? != 1 && $? != 4 && $? != 6)) ; then
  echo "Status code $?" >> /root/bootstrap.log
  exit 0
else
  echo "Status code $?" >> /root/bootstrap.log
  sleep 10;
  ts /vagrant/provision/tspuppet.sh
fi;
