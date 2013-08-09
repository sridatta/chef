# This recipe is intended to be run on Docker guests to create files in Docker's ubuntu:12.04 image

include_recipe 'apt'

package "ubuntu-minimal"

file "/etc/mtab" do
  owner   "root"
  group   "root"
  action  :create_if_missing
  content IO.read("/proc/mounts")
end

file "/etc/inittab" do
  owner  "root"
  group  "root"
  action :create_if_missing
end

directory "/etc/dhcp" do
  owner   "root"
  group   "root"
  action  :create
  only_if { !File.directory?("/etc/dhcp") }
end

apt_repository "ubuntu" do
  uri          "http://archive.ubuntu.com/ubuntu"
  distribution node['lsb']['codename']
  components   ["main", "universe"]
end
