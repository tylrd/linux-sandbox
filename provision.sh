set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get -qq update

HA_VERSION=1.8.8
HA_PATH="/tmp/haproxy-$HA_VERSION"

REDIS_VERSION=4.0.9
REDIS_PATH="/tmp/redis-$REDIS_VERSION"

CONSUL_VERSION=1.1.0

CONSUL_TMPL_VERSION=0.19.4
CONSUL_TMPL_PATH="/tmp/consul-template-$CONSUL_TMPL_VERSION"

CURL_OPTS="-sS"

apt-get -qq install -y \
  apache2-utils \
  jq \
  curl \
  git \
  unzip \
  build-essential \
  python-software-properties \
  software-properties-common \
  libssl-dev \
  libpcre3-dev

#########################################################
## haproxy
#########################################################
if ! command -v haproxy &> /dev/null; then
  curl $CURL_OPTS -o "$HA_PATH.tar.gz" "http://www.haproxy.org/download/1.8/src/haproxy-$HA_VERSION.tar.gz"
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
if ! command -v consul &> /dev/null; then
  curl $CURL_OPTS -o /tmp/consul.zip "https://releases.hashicorp.com/consul/"$CONSUL_VERSION"/consul_"$CONSUL_VERSION"_linux_amd64.zip"
  unzip /tmp/consul.zip -d /tmp
  cp /tmp/consul /usr/local/bin/consul

  if [ ! -d /var/log/consul ]; then
    mkdir -p /var/log/consul
  fi
fi

if [ ! -f /etc/init/consul.conf ]; then
  cp /vagrant/consul.conf /etc/init/consul.conf
  service consul start
fi

#########################################################
## consul-template
#########################################################
if ! command -v consul-template &> /dev/null; then
  [ ! -f "$CONSUL_TMPL_PATH.tgz" ] && curl $CURL_OPTS -o "$CONSUL_TMPL_PATH.tgz" \
    "https://releases.hashicorp.com/consul-template/$CONSUL_TMPL_VERSION/consul-template_${CONSUL_TMPL_VERSION}_linux_amd64.tgz"
  mkdir -p "$CONSUL_TMPL_PATH"
  tar -zxvf "$CONSUL_TMPL_PATH.tgz" -C "$CONSUL_TMPL_PATH" --strip-components=1
  cp "$CONSUL_TMPL_PATH/consul-template" "/usr/local/bin/consul-template"
fi

#########################################################
## redis
#########################################################
if ! command -v redis-server &> /dev/null; then
  curl $CURL_OPTS -o "$REDIS_PATH.tar.gz" "http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"
  mkdir -p "$REDIS_PATH"
  tar -zxvf "$REDIS_PATH.tar.gz" -C "$REDIS_PATH" --strip-components=1
  cd "$REDIS_PATH"
  make
  make install
else
  echo "Redis $REDIS_VERSION already installed!"
fi

#########################################################
## dotfiles
#########################################################
if ! test -d /home/vagrant/.bin; then
  curl $CURL_OPTS https://raw.githubusercontent.com/tylrd/dotfiles/master/.bin/install.sh | su vagrant -c /bin/bash
  su vagrant -c /home/vagrant/.bin/bootstrap.sh
fi
