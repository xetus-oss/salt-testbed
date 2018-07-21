class TestBedConfig
  def initialize(default_config, user_config)

    @default_config = default_config
    @user_config = user_config ? (user_config) : ({})

    #
    # Merge the default config with the user provided config. Careful! This only merges one 
    # level. No multi-level maps can be merged, so don't get too fancy with the configuration
    # or you'll pay the price here.
    #
    merged_config = {}
    ['vm_defaults'].each do |keyname|
      merged_keyval = @default_config[keyname].clone()
      if @user_config.has_key?(keyname)
        merged_keyval = merged_keyval.merge(@user_config[keyname])
      end
      merged_config[keyname] = merged_keyval
    end


    #
    # The vms tree is a special case, we need to merge each of the
    # top level keys contained in the tree.
    #
    merged_config['vms'] = @default_config['vms'].clone()
    if user_config.has_key?("vms")
      user_config['vms'].each do |keyname, value|
        if merged_config['vms'].has_key?(keyname) and merged_config['vms'][keyname] != nil
          merged_config['vms'][keyname] =
            merged_config['vms'][keyname].merge(value)
        else
          merged_config['vms'][keyname] = value
        end
      end
    end

    #
    # Inflate the vm maps with the defaults
    #
    @vm_defs = {}
    merged_config['vms'].each do |keyname, value|
      vm_def = value ? value : {}
      @vm_defs[keyname] = merged_config['vm_defaults'].merge(vm_def)
    end

    vm_order = ["primarymaster", "secondarymaster", "minion1", "minion2"]
    @ordered_vms = []
    vm_order.each do |vm_name|
      @ordered_vms.push({
        "name" => vm_name,
        "vm_config" => @vm_defs[vm_name]
      })
    end
  end

  def vms
    @ordered_vms
  end
end