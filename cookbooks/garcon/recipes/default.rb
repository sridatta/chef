user node.garcon.user do
  home   node.garcon.home
  shell  '/bin/bash'
  system true
  action :create
end

directory node.garcon.home do
  owner     node.garcon.user
  group     node.garcon.user
  recursive true
end

directory node.garcon.ssh_dir do
  owner  node.garcon.user
  group  node.garcon.user
  action :create
end

execute "generate-guest-ssh-keys" do
  user    node.garcon.user
  group   node.garcon.group
  command "ssh-keygen -q -f #{File.join(node.garcon.ssh_dir, 'id_rsa')} -N ''"
  creates File.join(node.garcon.ssh_dir, 'id_rsa')
end

file File.join(node.garcon.ssh_dir, "git_key") do
  mode    '0400'
  owner   node.garcon.user
  group   node.garcon.group
  content Chef::EncryptedDataBagItem.load('ssh-keys', 'airbnb_chef')['id_rsa']
end

file File.join(node.garcon.home, "git_wrapper") do
  mode    '0500'
  owner   node.garcon.user
  group   node.garcon.group
  content "ssh -i #{File.join(node.garcon.ssh_dir, "git_key")} -o StrictHostKeyChecking=no $1 $2"
end


# Create the chef-deploy.pem key from encrypted databag
['chef-deploy.pem', 'encrypted_data_bag_secret'].each do |filename|
  file File.join(node.garcon.ssh_dir, filename) do
    owner   node.garcon.user
    group   node.garcon.group
    content Chef::EncryptedDataBagItem.load('garcon', 'keys')[filename]
    mode    "600"
  end
end

# Create .ssh/config file that disables host key checking on the LXC subnet
cookbook_file File.join(node.garcon.ssh_dir, 'config') do
  source "ssh-config"
  owner  node.garcon.user
  group  node.garcon.group
  mode   "600"
end


include_recipe "apt::cacher-ng"

# Reconfigure apt-cacher-ng to only listen on LXC bridge interface
template node.garcon.apt_cacher.conf_file do
  source   "acng.conf.erb"
  owner    "root"
  group    "root"
  variables({
    :host_ip => node.docker.host_ip
  })
  notifies :restart, "service[apt-cacher-ng]"
end

include_recipe "garcon::docker"
include_recipe "garcon::garcon-server"

git File.join(node.garcon.home, "chef") do
  user node.garcon.user
  group node.garcon.user
  repository   node.garcon.chef_git_origin
  revision    node.garcon.chef_git_revision
  action      :sync
  ssh_wrapper File.join(node.garcon.home, "git_wrapper")
end

# Modify the ubuntu base image so it works with our fork
bash "docker-ubuntu-image" do
  user    "root"
  code <<-EOF
    #{node['go']['gobin']}/docker pull ubuntu:12.04
    docker_graph="/var/lib/docker/graph"
    ubuntu_id=`docker images | grep ubuntu | awk '{print $3}'`
    dir_list=(${docker_graph}/${ubuntu_id}*)
    image_dir="${dir_list[0]}"
    image_layer=$image_dir/layer/
    touch $image_layer/.dockerinit
    mkdir -p $image_layer/run/resolvconf
    touch $image_layer/run/resolvconf/resolv.conf
    rm $image_layer/etc/resolv.conf
    ln -s /run/resolvconf/resolv.conf $image_layer/etc/resolv.conf
  EOF
end
