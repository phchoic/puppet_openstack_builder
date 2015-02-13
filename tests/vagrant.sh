vagrant destroy -f infra1 infra2 infra3 proxy1 control1

vagrant up infra1 &
sleep 3
vagrant up infra2 &
sleep 3
vagrant up infra3 &

vagrant up proxy1
sleep 3
vagrant up control1
