class VMDefFactory
  def initialize(vagrant_config)
    @vagrant_config = vagrant_config
    @ip_counter = 20
  end

  def create_vm(name:, vm_config:)
     @ip_counter = @ip_counter + 1

     # Be sure to capture the IP counter now, since the block below
     # won't be evaluated until vagrant needs to define the VM.
     vm_ip = @ip_counter
     
     @vagrant_config.vm.define name, autostart: vm_config['auto_start'] do |vbox|
      vbox.vm.box = vm_config['box']

      vbox.vm.provider "virtualbox" do |v|
        v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
        v.memory = vm_config['memory']
        v.cpus = vm_config['cpus']
      end

      vbox.vm.network "private_network", ip: "192.168.50.#{vm_ip}"

      if vm_config["bridge_interface"]
        master.vm.network "public_network", bridge: vm_config["bridge_interface"]
      end

      # Step 1, set the host name
      vbox.vm.provision "set_hostname", type: "shell" do |s|
        hostname_value = name.gsub("_", "-")
        s.inline = "
          echo #{hostname_value} > /etc/hostname;
          hostname #{hostname_value};
          sed -r 's/^(127\.0\.1\.1.+)/\1 #{hostname_value}/'
          "
      end

      # Step 2, install salt
      vbox.vm.provision "install_salt", type: "salt" do |s|
        s.install_master = vm_config['salt_master']
        s.install_type = vm_config['salt_install_type']
        s.install_args = vm_config['salt_install_args']

        #
        # If you install the salt master, you get the salt-cloud with it
        #
        if vm_config['salt_master']
          s.bootstrap_options = "-L"
        end

      end

      # Step 3 setup the templates
      vbox.vm.provision "setup_templates", type: "shell" do |s|
        s.path = vm_config['post_install_script']
        s.env = {
          "MACHINE_NAME": name,
          "IS_MASTER": (vm_config['salt_master'])
        }
      end
    end
  end
end