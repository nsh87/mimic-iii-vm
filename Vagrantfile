# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "nshaas/ubuntu-14.04-large"

  config.vm.network "forwarded_port", guest: 5432, host: 2345

  config.vm.network "private_network", ip: "192.168.34.43"

  config.vm.provision :ansible do |ansible|

      ansible.playbook = "provisioning/mimic.yml"

  end

end
