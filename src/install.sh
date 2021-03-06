#!/bin/bash

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/common.sh

[ $(id -u) != "0" ] && { ansi --bold --bg-red "请用 root 账户执行本脚本"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`

function init_system {
    export LC_ALL="en_US.UTF-8"
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    locale-gen en_US.UTF-8
    locale-gen zh_CN.UTF-8
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    init_alias
}

function init_repositories {
    echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse' > /etc/apt/sources.list
    echo 'deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse' >> /etc/apt/sources.list
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    apt-get update
}

function install_basic_softwares {
    apt-get install -y curl git build-essential unzip supervisor software-properties-common
}

function install_php {
    apt-get install -y php7.2-bcmath php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-pgsql php7.2-readline php7.2-xml php7.2-zip
}

function install_mysql {
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"
    apt-get install -y mysql-server
    usermod -d /var/lib/mysql/ mysql
}

function install_nginx {
    apt-get remove -y apache2    
    apt-get install -y nginx    
    systemctl enable nginx.service
}

function install_memcached { 
    apt-get install -y memcached
}

function install_beanstalkd {
    apt-get install -y beanstalkd
}

function install_redis {
    apt-get install -y redis-server
}

function install_yarn {
    apt-get install -y yarn
    yarn config set registry https://registry.npm.taobao.org
}

function install_composer {
    apt-get install -y composer
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
}

function install_node_npm {
    apt-get install -y npm
    npm install -g n && n stable
    npm -g install npm@next
}

function init_ssh {
    apt-get remove -y --purge openssh-server
    apt-get install openssh-server
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
    service ssh --full-restart
}

function init_autoremove {    
    apt-get autoremove -y
}

function init_alias {
    alias wsl > /dev/null 2>&1 || {
        echo "alias wsl='service nginx start & service ssh start & service mysql start & service redis-server start & service php7.2-fpm start'" >> ~/.bash_aliases
    }    
}

call_function init_system "正在初始化系统" ${LOG_PATH}
call_function init_repositories "正在初始化软件源" ${LOG_PATH}
call_function install_basic_softwares "正在安装基础软件" ${LOG_PATH}
call_function install_php "正在安装PHP" ${LOG_PATH}
call_function install_mysql "正在安装Mysql" ${LOG_PATH}
call_function install_nginx "正在安装Nginx" ${LOG_PATH}
call_function install_memcached "正在安装Memcached" ${LOG_PATH}
call_function install_beanstalkd "正在安装Beanstalkd" ${LOG_PATH}
call_function install_redis "正在安装Redis" ${LOG_PATH}
call_function install_yarn "正在安装Yarn" ${LOG_PATH}
call_function install_composer "正在安装Composer" ${LOG_PATH}
call_function install_node_npm "正在安装/更新Node \ Npm" ${LOG_PATH}
call_function init_ssh "正在配置SSH" ${LOG_PATH}
call_function init_autoremove "正在执行自动清理" ${LOG_PATH}

ansi
ansi --green --bold "操作完成"
ansi
ansi -n "Mysql root 密码："
ansi --bold --bg-white --red ${MYSQL_ROOT_PASSWORD}
ansi
ansi --green --bold "1.请手动执行 $(ansi::yellow)source ~/.bash_aliases$(ansi::green) 使 alias 指令生效。"
ansi --green --bold "2.快捷启动PHP MYSQL SSH服务，只需 root用户下 运行 $(ansi::yellow)wsl$(ansi::green) "
ansi