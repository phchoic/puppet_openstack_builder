# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX = 'developervms/centos7-64'

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

  config.vm.provision :puppet do |puppet|
    puppet.module_path = "modules"
    puppet.manifest_file = "site.pp"
    puppet.hiera_config_path = "hiera/hiera.yaml"
    puppet.working_directory = "/vagrant/hiera/data"
  end
end

Vagrant.configure("2") do |config|
  ['1','2','3'].each do | i |

    config.vm.define "build#{i}" do |build|
      build.vm.hostname = "build#{i}"
      build.vm.network "private_network", :ip => "192.168.242.0#{i}"
      build.vm.network "private_network", :ip => "10.2.3.0#{i}"
      build.vm.network "private_network", :ip => "10.3.3.0#{i}"
      configure(build)
    end

    config.vm.define "control#{i}" do |control|
      control.vm.hostname = "control"
      control.vm.network "private_network", :ip => "192.168.242.1#{i}"
      control.vm.network "private_network", :ip => "10.2.3.1#{i}"
      control.vm.network "private_network", :ip => "10.3.3.1#{i}"
      configure(control)
    end

    config.vm.define "hypervisor#{i}" do |hypervisor|
      hypervisor.vm.hostname = "hypervisor#{i}"
      hypervisor.vm.network "private_network", :ip => "192.168.242.2#{i}"
      hypervisor.vm.network "private_network", :ip => "10.2.3.2#{i}"
      hypervisor.vm.network "private_network", :ip => "10.3.3.2#{i}"
      configure(hypervisor)
    end

  end
end
