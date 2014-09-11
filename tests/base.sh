vagrant destroy -f
# Bring up the control node and then reboot it to ensure
# it has an ip netns capable kernel
vagrant up control1
vagrant halt control1
vagrant up control1 --provision

# Bring up compute node
vagrant up compute1
vagrant halt compute1
vagrant up compute1 --provision

# Add routing to external bridge via eth0
vagrant ssh control1 -c "sudo sysctl -w net.ipv4.ip_forward=1"
vagrant ssh control1 -c "sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
vagrant ssh control1 -c "sudo iptables-save | sed 's/-A FORWARD -j REJECT --reject-with icmp-host-prohibited/-A FORWARD -i eth0 -o br-ex -m state --state RELATED,ESTABLISHED -j ACCEPT\n-A FORWARD -i br-ex -o eth0 -j ACCEPT\n-A FORWARD -j REJECT --reject-with icmp-host-prohibited/' - > /tmp/ipt"
vagrant ssh control1 -c "sudo iptables-restore /tmp/ipt"
vagrant ssh control1 -c "sudo ip addr add 172.16.2.1/24 dev br-ex"

# Run test
vagrant ssh control1 -c "sudo bash -x /tmp/test_nova.sh"



