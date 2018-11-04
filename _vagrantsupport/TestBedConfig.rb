class TestBedConfig

  def deep_merge(first, second)
    if [:undefined, nil, :nil].include?(first)
      return second
    end

    if [:undefined, nil, :nil].include?(second)
      return first
    end

    deep_merge_strategy = proc { |key, v1, v2|
      Hash === v1 && Hash === v2 ? 
        v1.merge(v2, &deep_merge_strategy) : 
        [:undefined, nil, :nil].include?(v2) ? v1 : v2 
    }

    first.merge(second, &deep_merge_strategy)
  end

  def initialize(default_config, user_config)
    @default_config = default_config
    @user_config = user_config ? (user_config) : ({})
    @ip_tracker = IpTracker.new

    #
    # Merge the default config with the user provided config.
    #
    merged_config = {}
    merged_config['vm_defaults'] = self.deep_merge(
      @default_config['vm_defaults'].clone(), 
      @user_config['vm_defaults']
    )

    #
    # The vms tree is a special case, we need to merge each of the
    # top level keys contained in the tree.
    #
    merged_config['vms'] = self.deep_merge(
      @default_config['vms'].clone(),
      @user_config['vms']
    )

    #
    # Inflate the vm maps with the defaults
    #
    @vm_defs = {}
    merged_config['vms'].each do |keyname, value|
      if value
        @vm_defs[keyname] = self.deep_merge(merged_config['vm_defaults'], value)
      end
    end

    vm_order = ["primarymaster", "secondarymaster", "minion1", "minion2", "winminion"]
    @ordered_vms = []
    vm_order.each do |vm_name|
      if @vm_defs[vm_name]
        @ordered_vms.push({
          "name" => vm_name,
          "vm_config" => @vm_defs[vm_name]
        })
      end
      #
      # Add un-created VMs to the ip tracker to ensure the same static IPs
      # regardless of which VMs are created
      #
      @ip_tracker.add_vm(vm_name)
    end
  end

  def ip_tracker
    @ip_tracker
  end

  def vms
    @ordered_vms
  end
end

#
# A simple state object that tracks whcih VM has which IP
#
class IpTracker
  def initialize(ip_prefix = "192.168.50")
    @ip_prefix = ip_prefix
    @ip_counter = 20
    @vm_to_ip = {}
  end

  def add_vm(name)
    if !@vm_to_ip.has_key?(name)
      @ip_counter = @ip_counter + 1
      @vm_to_ip[name] = "#{@ip_prefix}.#{@ip_counter}"
    end
    get_ip(name)
  end

  def get_ip(name)
    @vm_to_ip[name]
  end
end