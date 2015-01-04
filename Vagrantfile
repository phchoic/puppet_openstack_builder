# -*- mode: ruby -*-
# vi: set ft=ruby :

#BOX = 'developervms/centos7-64'
BOX = 'vStone/centos-7.x-puppet.3.x'

def configure(config)
  config.vm.box = BOX
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
  end

  config.vm.provider "virtualbox" do |vconfig|
    vconfig.customize ["modifyvm", :id, "--memory", "4096"]
    vconfig.cpus = 2
  end

  config.vm.provision :shell do |shell|
    shell.inline = 'bash /vagrant/provision/bootstrap.sh'
  end
end

Vagrant.configure("2") do |config|

  config.vm.define "build1" do |infra|
    infra.vm.hostname = "build1"
    infra.vm.network "private_network", :ip => "192.168.242.5"
    infra.vm.network "private_network", :ip => "10.2.3.5"
    configure(infra)
  end

  ['1','2','3'].each do | i |

    config.vm.define "infra#{i}" do |infra|
      infra.vm.hostname = "infra#{i}"
      infra.vm.network "private_network", :ip => "192.168.242.3#{i}"
      infra.vm.network "private_network", :ip => "10.2.3.3#{i}"
      configure(infra)
    end

    config.vm.define "control#{i}" do |control|
      control.vm.hostname = "control"
      control.vm.network "private_network", :ip => "192.168.242.1#{i}"
      control.vm.network "private_network", :ip => "10.2.3.1#{i}"
      configure(control)
    end

    config.vm.define "hyper#{i}" do |hyper|
      hyper.vm.hostname = "hyper#{i}"
      hyper.vm.network "private_network", :ip => "192.168.242.2#{i}"
      hyper.vm.network "private_network", :ip => "10.2.3.2#{i}"
      configure(hyper)
    end
  end
end
