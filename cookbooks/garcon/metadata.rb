maintainer       "Sridatta Thatipamala"
maintainer_email "sridatta.thatipamala@airbnb.com"
description      "Installs the garcon application"
version          "0.0.1"

depends          "apt"

%w{ ubuntu debian }.each do |os|
  supports os
end
