# -*- mode: ruby -*-
# vi: set ft=ruby :

#BOX = 'developervms/centos7-64'
BOX = 'vStone/centos-7.x-puppet.3.x'

def configure(config, memory="4096", provisioner=nil, role=nil)
  config.vm.box = BOX
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
  end

  config.vm.provider "virtualbox" do |vconfig|
    vconfig.customize ["modifyvm", :id, "--memory", memory]
    vconfig.cpus = 2
  end

  config.vm.provision :shell do |shell|
    shell.inline = 'cp /vagrant/hiera/data/cloudinit.yaml /tmp/cloudinit.yaml'
  end

  if role
    config.vm.provision :shell do |shell|
      shell.inline = "echo 'role: #{role}' >> /tmp/cloudinit.yaml"
    end
  end

  if provisioner
    config.vm.provision :shell do |shell|
      shell.inline = "echo 'provisioner: #{provisioner}' >> /tmp/cloudinit.yaml"
    end
  end

  config.vm.provision :shell do |shell|
    shell.inline = 'bash /vagrant/provision/bootstrap.sh | tee /root/bootstrap.log'
  end
end

Vagrant.configure("2") do |config|

  config.vm.define "build1" do |infra|
    infra.vm.hostname = "build1"
    infra.vm.network "private_network", :ip => "192.168.242.5"
    infra.vm.network "private_network", :ip => "10.2.3.5"
    configure(infra, memory='1024')
  end

  ['1','2','3'].each do | i |

    config.vm.define "infra#{i}" do |infra|
      infra.vm.hostname = "infra#{i}"
      infra.vm.network "private_network", :ip => "192.168.242.3#{i}"
      infra.vm.network "private_network", :ip => "10.2.3.3#{i}"
      configure(infra, memory='768')
    end

    config.vm.define "control#{i}" do |control|
      control.vm.hostname = "control#{i}"
      control.vm.network "private_network", :ip => "192.168.242.1#{i}"
      control.vm.network "private_network", :ip => "10.2.3.1#{i}"
      configure(control, memory='3096')
    end

    config.vm.define "proxy#{i}" do |proxy|
      proxy.vm.hostname = "proxy#{i}"
      proxy.vm.network "private_network", :ip => "192.168.242.4#{i}"
      proxy.vm.network "private_network", :ip => "10.2.3.4#{i}"
      configure(proxy, memory='1024')
    end

    config.vm.define "hyper#{i}" do |hyper|
      hyper.vm.hostname = "hyper#{i}"
      hyper.vm.network "private_network", :ip => "192.168.242.2#{i}"
      hyper.vm.network "private_network", :ip => "10.2.3.2#{i}"
      configure(hyper, memory='2560')
    end
  end
end
