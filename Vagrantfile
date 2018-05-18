# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    set -x

    export DEBIAN_FRONTEND=noninteractive
    apt-get -qq update

    HA_VERSION=1.8.8
    HA_PATH="/tmp/haproxy-$HA_VERSION"

    REDIS_VERSION=4.0.9
    REDIS_PATH="/tmp/redis-$REDIS_VERSION"

    CONSUL_VERSION=1.1.0

    CURL_OPTS="-sS"

    apt-get -qq install -y \
      apache2-utils \
      jq \
      curl \
      unzip \
      build-essential \
      python-software-properties \
      software-properties-common \
      libssl-dev \
      libpcre3-dev

    #########################################################
    ## haproxy
    #########################################################
    if ! test -f "$HA_PATH.tar.gz"; then
      curl $CURL_OPTS -o "$HA_PATH.tar.gz" http://www.haproxy.org/download/1.8/src/haproxy-$HA_VERSION.tar.gz
      mkdir -p "$HA_PATH"
      tar -zxvf "$HA_PATH.tar.gz" -C "$HA_PATH" --strip-components=1
      cd "$HA_PATH"
      make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LIBCRYPT=1
      make install
    else
      echo "HAProxy $HA_VERSION already installed!"
    fi

    #########################################################
    ## consul
    #########################################################
    if ! test -f /tmp/consul.zip; then
      curl $CURL_OPTS -o /tmp/consul.zip https://releases.hashicorp.com/consul/"$CONSUL_VERSION"/consul_"$CONSUL_VERSION"_linux_amd64.zip
      unzip /tmp/consul.zip -d /tmp
      mv /tmp/consul /usr/bin/consul
    fi

    if ! test -d /var/log/consul; then
      mkdir -p /var/log/consul
    fi

    # run consul in background
    nohup /usr/bin/consul agent -dev 0<&- &> /var/log/consul/consul.log &

    #########################################################
    ## redis
    #########################################################
    if ! test -f "$REDIS_PATH.tar.gz"; then
      curl $CURL_OPTS -o "$REDIS_PATH.tar.gz" "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
      mkdir -p "$REDIS_PATH"
      tar -zxvf "$REDIS_PATH.tar.gz" -C "$REDIS_PATH" --strip-components=1
      cd "$REDIS_PATH"
      make
      make install
    else
      echo "Redis $REDIS_VERSION already installed!"
    fi
  SHELL
end
