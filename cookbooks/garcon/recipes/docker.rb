package "aufs-tools"
package "lxc"
package "bsdtar"

# If aufs isn't available, do our best to install the correct 
# linux-image-extra package. This is somewhat messy because the
# naming of these packages is very inconsistent across kernel
# versions
extra_package = %x(apt-cache search linux-image-extra-`uname -r | grep --only-matching -e [0-9]\.[0-9]\.[0-9]-[0-9]*` | cut -d " " -f 1).strip
unless extra_package.empty?
  package extra_package do
    not_if { "modprobe -l | grep aufs" }
  end
end

execute "create docker repo" do
  creates node.docker.go_repo
  command "mkdir -p #{node.docker.go_repo}"
end

git File.join(node.docker.go_repo, "docker") do
  repository  node.docker.git_origin
  revision    "garcon"
  action      :sync
  ssh_wrapper File.join(node.garcon.home, "git_wrapper")
  notifies    :run, "execute[install-docker]", :immediately
end

execute "install-docker" do
  cwd        File.join(node.docker.go_repo, "docker")
  command <<-EOF
  #{node['go']['install_dir']}/go/bin/go get -v github.com/dotcloud/docker/
  #{node['go']['install_dir']}/go/bin/go install -v github.com/dotcloud/docker/
  cd docker
  #{node['go']['install_dir']}/go/bin/go install
  EOF
  environment({
    'GOPATH' => node['go']['gopath'],
    'GOBIN' => node['go']['gobin']
  })
  action     :nothing
end

template "/etc/init/dockerd.conf" do
  source "dockerd.conf"
  mode   "0600"
  owner  "root"
  group  "root"
end

service "dockerd" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action   [ :start ]
end
