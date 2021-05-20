# -*- mode: ruby -*
# vi: set ft=ruby :
# require 'getoptlong'

# opts = GetoptLong.new(
#   [ '--custom-option', GetoptLong::OPTIONAL_ARGUMENT ]
# )

# customParameter=''

# opts.each do |opt, arg|
#   case opt
#     when '--custom-option'
#       customParameter=arg
#   end
# end
## Farklı ortamlar için hazırlanacak
# if OS.windows?
#     puts "Vagrant launched from windows."
# elsif OS.mac?
#     puts "Vagrant launched from mac."
# elsif OS.unix?
#     puts "Vagrant launched from unix."
# elsif OS.linux?
#     puts "Vagrant launched from linux."
# else
#     puts "Vagrant launched from unknown platform."
# end
Vagrant.configure("2") do |config|
   ### only ubuntu2004 and fedora

   #config.vm.box = "generic/ubuntu2004"
   config.vm.box = "generic/fedora31"
   config.vm.provision "shell", path: "mongodb-install.sh"  
   #config.vm.provision "shell", path: "mongodb-run.sh", run: "always"
   config.vm.network "forwarded_port", guest: 27017, host: 27017
   config.vm.network "forwarded_port", guest: 27018, host: 27018
   config.vm.network "forwarded_port", guest: 27019, host: 27019

  ##Virtualbox
  #  config.vm.provider "virtualbox" do |vb|
  #   vb.name = 'mongodb-replicaset'    
  #   vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  #   vb.memory = 4096
  #   vb.cpus = 2
  #  end
  ##vmware
  #  config.vm.provider "vmware_desktop" do |v|
  #   v.vmx["memsize"] = "4096"
  #   v.vmx["numvcpus"] = "2"
  #  end
  ## Libvirt
   config.vm.provider :libvirt do |kvm|
    kvm.memory = 4096
    kvm.cpus = 2
    # kvm.volume_cache = 'none'
    # kvm.storage_pool_name = 'vagrant-mongodb'
   end

end
