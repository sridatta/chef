default.garcon.user = "garcon"
default.garcon.group = "garcon"
default.garcon.home =  File.join('/home', node.garcon.user)
default.garcon.ssh_dir = File.join(node.garcon.home, '.ssh')
default.garcon.apt_cacher.conf_file = "/etc/apt-cacher-ng/acng.conf"

default.garcon.client_download_dir = File.join(node.garcon.home, "garcon-client")
default.garcon.client_git_origin = "git@github.com:airbnb/garcon.git"
default.garcon.client_git_ref = "server"
default.garcon.chef_git_origin = "git@github.com:airbnb/chef.git"
default.garcon.chef_git_revision = "garcon"

default.docker.host_ip = "172.16.42.1"
default.docker.host_iface = "docker0"
default.docker.git_origin = "git@github.com:airbnb/docker.git"
default.docker.go_repo = "/opt/go/src/github.com/dotcloud"

default.garcon.json_config = File.join(node.garcon.home,'config.json')
