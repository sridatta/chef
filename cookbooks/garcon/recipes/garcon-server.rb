include_recipe 'ruby'

gem_package "bundler"
gem_package "rake"

# Docker gemspec installs rspec but Rakefile needs rspec to run...
gem_package "rspec"

package "ruby1.9.1-dev"

git File.join(node.garcon.home, "docker-client") do
  repository  "git@github.com:sridatta/docker-client.git"
  revision    "master"
  action      :sync
  user        node.garcon.user
  group       node.garcon.group
  ssh_wrapper File.join(node.garcon.home, "git_wrapper")
end

# For some reason libcurl3 is pinned to this version,
# so the dev package should also.
apt_preference 'libcurl4-openssl-dev' do
  pin           'version 7.22.0-3ubuntu4.1-airbnb0'
  pin_priority '1001'
end

package "libcurl4-openssl-dev"

bash "install-docker-gem" do
  cwd    File.join(node.garcon.home, "docker-client")
  user   "root"
  code <<EOC
    eval `ssh-agent -s`
    ssh-add /home/garcon/.ssh/git_key
    bundle install
    rake install
EOC
end

git File.join(node.garcon.home, "garcon-client") do
  repository  node.garcon.client_git_origin
  revision    node.garcon.client_git_ref
  action      :sync
  user        node.garcon.user
  group       node.garcon.group
  ssh_wrapper File.join(node.garcon.home, "git_wrapper")
  notifies :run, "bash[install-garcon-gem]"
  notifies :restart, "runit_service[garcon]"
end

bash "install-garcon-gem" do
  action :nothing
  cwd     node.garcon.client_download_dir
  user    node.garcon.user
  environment ({'GEM_HOME' => File.join(node.garcon.home,'.gem'), 'GIT_SSH' => File.join(node.garcon.home, "git_wrapper") })
  code <<EOC
    eval `ssh-agent -s`
    ssh-add #{File.join node.garcon.ssh_dir, 'git_key'}
    bundle install
    rake install
EOC
end

file node.garcon.json_config do
  user  node.garcon.user
  group node.garcon.group
  notifies :restart, "runit_service[garcon]"
  content JSON.pretty_generate({
    "git_key" => File.join(node.garcon.ssh_dir, "chef-deploy.pem"),
    "chef_secret" => File.join(node.garcon.ssh_dir, "encrypted_data_bag_secret"),
    "ssh_public_key" => File.join(node.garcon.ssh_dir, "id_rsa.pub"),
    "ssh_private_key" => File.join(node.garcon.ssh_dir, "id_rsa"),
    "watchers" => [
      {
        "type" => "github",
        "port" => "4567",
      }
    ],
    "git_repos" => {
        "git@github.com:airbnb" => {
          "key" => Chef::EncryptedDataBagItem.load('ssh-keys', 'airbnb_chef')['id_rsa'],
        },
    },
  })
end

runit_service "garcon"
