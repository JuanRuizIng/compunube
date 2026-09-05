# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600


  # 1. SERVIDOR WEB 1 (Consul Server + Web App NodeJS)
  config.vm.define :servidorUbuntu do |servidorUbuntu|
    servidorUbuntu.vm.box = "bento/ubuntu-22.04"
    servidorUbuntu.vm.network :private_network, ip: "192.168.100.3"
    servidorUbuntu.vm.hostname = "servidorUbuntu"
    servidorUbuntu.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    servidorUbuntu.vm.provision "shell", path: "scripts/setup-servidor.sh"
  end

  # 2. SERVIDOR WEB 2 (Consul Client + Web App NodeJS)
  config.vm.define :clienteUbuntu do |clienteUbuntu|
    clienteUbuntu.vm.box = "bento/ubuntu-22.04"
    clienteUbuntu.vm.network :private_network, ip: "192.168.100.2"
    clienteUbuntu.vm.hostname = "clienteUbuntu"
    clienteUbuntu.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    clienteUbuntu.vm.provision "shell", path: "scripts/setup-cliente.sh"
  end

  # 3. BALANCEADOR DE CARGA (HAProxy + Consul Client)
  config.vm.define :balancer do |balancer|
    balancer.vm.box = "bento/ubuntu-22.04"
    balancer.vm.network :private_network, ip: "192.168.100.4"
    balancer.vm.hostname = "balancer"
    balancer.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
    balancer.vm.provision "shell", path: "scripts/setup-balancer.sh"
  end

end
