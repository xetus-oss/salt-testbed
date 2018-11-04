require_relative 'UbuntuVMDefFactory.rb'
require_relative 'WindowsVMDefFactory.rb'


class VMDefFactory
  def initialize(vagrant_config)
    @vagrant_config = vagrant_config
    @ubuntu_factory = UbuntuVMDefFactory.new(vagrant_config)
    @windows_factory = WindowsVMDefFactory.new(vagrant_config)
  end

  def create_vm(ip_tracker:, name:, vm_config:)
    if vm_config['windows']
      @windows_factory.create_vm(ip_tracker: ip_tracker, name: name, vm_config: vm_config)
    else
      @ubuntu_factory.create_vm(ip_tracker: ip_tracker, name: name, vm_config: vm_config)
    end
  end
end