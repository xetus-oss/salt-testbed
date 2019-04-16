class UbuntuVMDefFactory
  def initialize(vagrant_config)
    @vagrant_config = vagrant_config
  end

  def create_vm(ip_tracker:, name:, vm_config:)
     @vagrant_config.vm.define name, autostart: vm_config['auto_start'] do |vbox|
      vbox.vm.box = vm_config['ubuntu_config']['box']

      vbox.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--uartmode1", "disconnected" ]
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
        v.memory = vm_config['memory']
        v.cpus = vm_config['cpus']
      end

      vbox.vm.network "private_network", ip: (ip_tracker.get_ip name)

      if vm_config["bridge_interface"]
        master.vm.network "public_network", bridge: vm_config["bridge_interface"]
      end

      hostname_value = name.gsub("_", "-")

      # Step 1, set the host name
      vbox.vm.provision "set_hostname", type: "shell" do |s|
        s.inline = "
          echo #{hostname_value} > /etc/hostname;
          hostname #{hostname_value};
          sed -r 's/^(127\.0\.1\.1.+)/\1 #{hostname_value}/'
          "
      end

      # Step 2, install salt
      vbox.vm.provision "install_salt", type: "salt" do |s|
        s.install_master = vm_config['ubuntu_config']['salt_master']
        s.install_type = vm_config['ubuntu_config']['salt_install_type']
        s.install_args = ["#{vm_config['version']}", vm_config['ubuntu_config']['salt_install_args']].flatten.compact.join(" ")
        s.minion_id = hostname_value
        if !vm_config['ubuntu_config']['salt_master']
          s.master_id = (ip_tracker.get_ip'primarymaster')
        end

        s.bootstrap_options = ""
        if vm_config['ubuntu_config']['salt_bootstrap_options']
          s.bootstrap_options += " " + vm_config['ubuntu_config']['salt_bootstrap_options']
        end

        #
        # If you install the salt master, you get the salt-cloud with it
        #
        if vm_config['ubuntu_config']['salt_master']
          s.bootstrap_options += " -L"
        end
      end

      # Step 3 setup the templates
      if vm_config['ubuntu_config']['post_install_script']
        vbox.vm.provision "setup_templates", type: "shell" do |s|
          s.path = vm_config['ubuntu_config']['post_install_script']
          s.env = {
            "MACHINE_NAME": name,
            "IS_MASTER": (vm_config['ubuntu_config']['salt_master'])
          }
        end
      end
    end
  end
end