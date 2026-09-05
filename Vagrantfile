# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|

  # Imagen base
  config.vm.box = "ubuntu/jammy64"

  # Evitar actualizaciones automáticas de la box
  config.vm.box_check_update = false

  # ------------------------------------------------
  # LOAD BALANCER
  # ------------------------------------------------
  config.vm.define "loadbalancer" do |lb|

    lb.vm.hostname = "loadbalancer"

    lb.vm.network "private_network",
      ip: "192.168.100.10"  

    lb.vm.provider "virtualbox" do |vb|
      vb.name = "microproyecto1-loadbalancer"
      vb.memory = 512
      vb.cpus = 1
    end

    lb.vm.provision "shell",
    path: "scripts/install-consul.sh"
  
    lb.vm.provision "shell",
      path: "scripts/configure-consul.sh"
    
    lb.vm.provision "shell",
      path: "scripts/provision-haproxy.sh"

  end


  # ------------------------------------------------
  # WEB SERVER 1
  # ------------------------------------------------
  config.vm.define "web1" do |web1|

    web1.vm.hostname = "web1"

    web1.vm.network "private_network",
      ip: "192.168.100.11"

    web1.vm.provider "virtualbox" do |vb|
      vb.name = "microproyecto1-web1"
      vb.memory = 512
      vb.cpus = 1
    end

    web1.vm.provision "shell",
    path: "scripts/install-consul.sh"
  
    web1.vm.provision "shell",
      path: "scripts/configure-consul.sh"
    
    web1.vm.provision "shell",
      path: "scripts/provision-web.sh"

  end


  # ------------------------------------------------
  # WEB SERVER 2
  # ------------------------------------------------
  config.vm.define "web2" do |web2|

    web2.vm.hostname = "web2"

    web2.vm.network "private_network",
      ip: "192.168.100.12"

    web2.vm.provider "virtualbox" do |vb|
      vb.name = "microproyecto1-web2"
      vb.memory = 512
      vb.cpus = 1
    end
    
    web2.vm.provision "shell",
    path: "scripts/install-consul.sh"
  
    web2.vm.provision "shell",
      path: "scripts/configure-consul.sh"
    
    web2.vm.provision "shell",
      path: "scripts/provision-web.sh"
  end

end