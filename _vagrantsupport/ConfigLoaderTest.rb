abs_base_path = File.dirname(File.absolute_path(__FILE__))
require  abs_base_path+'/TestBedConfig.rb'
require 'yaml'
require 'pp'

#
# A fairly simply unit test loader for the TestBedConfig file
#

default_config_path = "#{abs_base_path}/../testbed-defaults.yaml"


print "Loading defaults file..."
$stdout.flush

if not File.file?(default_config_path)
  raise Exception.new, "Cannot find default configuration at #{default_config_path}"
end

default_config = YAML.load_file(default_config_path)
print "ok\n"
$stdout.flush

# ---------- Test Case 1
print "Testing construction using existing defaults and no overrides..."
$stdout.flush

default_config = TestBedConfig.new(default_config, {})
print "ok \n"
$stdout.flush


test_case_1_config = YAML.load(%{
vms:
  primarymaster:
    auto_start: true
    ubuntu_config:
      salt_master: true

vm_defaults:
  ubuntu_config:
    box: ubuntu/bionic64
})

expected_vms = [{
  "name" => "primarymaster",
  "vm_config" => {
    "auto_start" => true,
    "ubuntu_config" => {
      "box" => "ubuntu/bionic64",
      "salt_master" => true
    }
  }
}]

# ---------- Test Case 2
print "Testing correct output post merge without overrides..."
$stdout.flush

tbConfig = TestBedConfig.new(test_case_1_config, {})
if tbConfig.vms() != expected_vms
  print "Failed! \n"
  print "Found:\n#{tbConfig.vms().pretty_inspect()} \n...but expected:\n #{expected_vms.pretty_inspect()}\n"
  exit(1)
else
  print "ok \n"
end
$stdout.flush


user_override_config =  {"vms" =>
  { "primarymaster" => {
    "ubuntu_config" => { "box" => "something/else" } }
  }
}

expected_vms = [{
  "name" => "primarymaster",
  "vm_config" => {
    "auto_start" => true,
    "ubuntu_config" => {
      "box" => "something/else",
      "salt_master" => true
    }
  }
}]

# ---------- Test Case 3
print "Testing correct output post merge with vms overrides..."
$stdout.flush

tbConfig = TestBedConfig.new(test_case_1_config, user_override_config)
if tbConfig.vms() != expected_vms
  print "Failed! \n"
  print "Found:\n#{tbConfig.vms().pretty_inspect()} \n...but expected:\n #{expected_vms.pretty_inspect()}\n"
else
  print "ok \n"
end
$stdout.flush



user_override_config =  { "vm_defaults" => { "ubuntu_config" => { "box" => "something/else" } } } 
expected_vms = [{
  "name" => "primarymaster",
  "vm_config" => {
    "auto_start" => true,
    "ubuntu_config" => {
      "box" => "something/else",
      "salt_master" => true
    }
  }
}]
# ---------- Test Case 4
print "Testing correct output post merge with vm_defaults overrides..."
$stdout.flush

tbConfig = TestBedConfig.new(test_case_1_config, user_override_config)
if tbConfig.vms() != expected_vms
  print "Failed! \n"
  print "Found:\n#{tbConfig.vms().pretty_inspect()} \n...but expected:\n #{expected_vms.pretty_inspect()}\n"
else
  print "ok \n"
end
$stdout.flush