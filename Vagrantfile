# -*- mode: ruby -*-
# vi: set ft=ruby :

#Root specific configuration - install packages etc.
$provision_root = <<'SCRIPT_ROOT'
sudo apt-get update
sudo apt-get install -y git python-pip python-dev build-essential openjdk-7-jre openjdk-7-jdk maven
sudo apt-get -y autoremove

# Install app dependencies
cd /vagrant
sudo pip install -r python/requirements.txt

# Make vi look nice
echo "colorscheme desert" > ~/.vimrc


#echo "fetch, install docker ce"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y  docker-ce=17.03.0~ce-0~ubuntu-trusty
groupadd docker
usermod -aG docker vagrant

# Add docker-compose
sudo pip install docker-compose
SCRIPT_ROOT

#User specific configuration
$provision_user = <<'SCRIPT_USER'


#Set up some niceities in the shell
cat <<'EOF_BASHRC' > $HOME/.bashrc
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.bash_eternal_history
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

alias ls='ls --color=auto'
export PS1='\n\@ \w \e[0;32m $(__git_ps1 "(%s)") \e[m \n: \u@\h \j %; '
export PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n$ '

cd /vagrant
EOF_BASHRC

SCRIPT_USER


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  config.vm.box = "ubuntu/trusty64"
  #config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "private_network", ip: "192.168.33.10"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 1
  end

  # Copy your .gitconfig file so that your git credentials are correct
  if File.exists?(File.expand_path("~/.gitconfig"))
    config.vm.provision "file", source: "~/.gitconfig", destination: "~/.gitconfig"
  end

  config.vm.provision :shell, inline: $provision_root
  config.vm.provision :shell, privileged: false, inline: $provision_user
end
