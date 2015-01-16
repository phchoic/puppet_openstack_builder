if ! yum list installed consul > /dev/null 2>&1; then
  yum install -y consul
fi

infra1_internal=None
if [ -e /dev/disk/by-label/config-2 ]; then
    infra1_internal=`cat /mnt/config/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('infra1_internal', None)"`
elif curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json &> /dev/null; then
    infra1_internal=`curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('infra1_internal', None)"`
fi
if mount | grep -q vagrant; then
    if [ "$(hostname | grep -oh '^[[:alpha:]]*')" = "build" ] ; then
        infra1_internal="None"
    else
        infra1_internal="192.168.242.5"
    fi
fi
if [ "$infra1_internal" = "None" ] ; then
  echo "ERROR: infra1_internal could not be found."
fi

internal_iface=None
if [ -e /dev/disk/by-label/config-2 ]; then
    internal_iface=`cat /mnt/config/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('internal_iface', None)"`
elif curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json &> /dev/null; then
    internal_iface=`curl --fail --silent --show-error http://169.254.169.254/openstack/latest/meta_data.json | python -c "import sys, json; print json.load(sys.stdin)['meta'].get('internal_iface', None)"`
fi
if mount | grep -q vagrant; then
    if [ "$(hostname | grep -oh '^[[:alpha:]]*')" = "build" ] ; then
        internal_iface="None"
    else
        internal_iface="enp0s8"
    fi
fi
if [ "$internal_iface" = "None" ] ; then
  echo "ERROR: internal_iface could not be found."
fi

internal_address=`facter ipaddress_${internal_iface}`
cat > /etc/consul.d/config.json<<EOF
{
    "addresses": {
        "dns": "127.0.0.1",
        "http": "127.0.0.1",
        "rpc": "127.0.0.1"
    },
    "bind_addr": "${internal_address}",
    "data_dir": "/var/lib/consul",
    "enable_syslog": true,
    "log_level": "INFO",
    "node_name": "proxy",
    "retry_join": [
        "${infra1_internal}"
    ]
}
EOF

systemctl start consul
systemctl enable consul
