if ! yum list installed confd > /dev/null 2>&1; then
  yum install -y confd
fi

cat > /etc/confd/confd.toml<<EOF
backend = "consul"
confdir = "/etc/confd"
scheme = "http"
nodes = [
  "http://127.0.0.1:8500"
]
prefix = "/v1/"
interval = 600
EOF

confd -config-file="/etc/confd/confd.toml" -onetime=true
