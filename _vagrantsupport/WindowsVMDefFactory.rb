class WindowsVMDefFactory
  def initialize(vagrant_config)
    @vagrant_config = vagrant_config
  end

  def create_vm(ip_tracker:, name:, vm_config:)
    @vagrant_config.vm.define name, autostart: vm_config['auto_start'] do |vbox|
      vbox.vm.box = vm_config['windows_config']['box']

      vbox.vm.provider "virtualbox" do |v|
        v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
        v.memory = vm_config['memory']
        v.cpus = vm_config['cpus']
      end

      vbox.vm.network "private_network", ip: (ip_tracker.get_ip name)

      if vm_config["bridge_interface"]
        master.vm.network "public_network", bridge: vm_config["bridge_interface"]
      end

      # Step 1, install salt
      vbox.vm.provision "install_salt", type: "salt" do |s|
        hostname_value = name.gsub("_", "-")
        s.minion_id = hostname_value
        s.master_id = ip_tracker.get_ip('primarymaster')
      end


      # Step 2, setup symlinked salt management paths
      if vm_config['windows_config']['post_install_script']
        vbox.vm.provision "setup_templates", type: "shell" do |s|
          s.path = vm_config['windows_config']['post_install_script']
          s.env = { "MACHINE_NAME": name }
          s.privileged = true
        end
      end

      vbox.trigger.after :up do |trigger|
        trigger.name = "Ensure the salt-minion service uses mounted c:\salt\conf"
        trigger.run_remote = { inline: "Restart-Service salt-minion" }
      end
    end
  end
end