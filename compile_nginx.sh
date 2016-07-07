#!/bin/bash
if [[ $USER != "root" ]]; then 
	echo "This script must be run as root!" 
	exit 1
fi 

# get OS
# MY_OS=`cat /etc/*release | grep "^ID=" | cut -d"=" -f2`
cp init.d/nginx-centos /etc/init.d/nginx
chmod +x /etc/init.d/nginx

########################################################
SOURCES_FOLDER="/opt/sources"

if [ -d "$SOURCES_FOLDER" -a ! -h "SOURCES_FOLDER" ]; then
	echo "Everything will be saved in $SOURCES_FOLDER"
else
	echo "Created folder $SOURCES_FOLDER, Everything will be saved in this folder"
	mkdir -p "$SOURCES_FOLDER"
fi

########################################################
echo "Installing required libraries"
if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y libpcre3 libpcre3-dev libperl-dev lua5.1 liblua5.1-0 liblua5.1-0-dev git
    apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-prefork-dev libxml2-dev libcurl4-openssl-dev
    apt-get install -y libxml2-dev libxslt1-dev python-dev
    apt-get install -y libgd2-xpm-dev
    apt-get install -y libgeoip-dev
elif [ -f /etc/redhat-release ]; then
    yum -y upadte
    yum install -y httpd git redis lua lua-devel gcc gcc-c++ kernel-devel unzip openssl openssl-devel readline-devel
    yum install -y pcre pcre-devel libxml2 libxml2-devel curl curl-devel httpd-devel
    yum install -y openssl openssl-devel
    yum install -y libxml2-devel libxslt-devel
    yum install -y gd-devel
    yum install -y geoip-devel
fi

########################################################
echo "Downloading Nginx, Plugins, Mod Security"
git clone "https://github.com/openresty/lua-nginx-module.git" "$SOURCES_FOLDER/lua-nginx-module"
git clone "https://github.com/openresty/set-misc-nginx-module.git" "$SOURCES_FOLDER/set-misc-nginx-module"
git clone "https://github.com/simpl/ngx_devel_kit.git" "$SOURCES_FOLDER/ngx_devel_kit"
git clone "https://github.com/trieuvutrung/Nginx-RestrictIP-Redis.git" "$SOURCES_FOLDER/restrictip-lua"
wget "http://nginx.org/download/nginx-1.9.9.tar.gz" -O "$SOURCES_FOLDER/nginx-1.9.9.tar.gz"
git clone "https://github.com/trieuvutrung/modsecurity-2.8.0.git" "$SOURCES_FOLDER/modsecurity-2.8.0"

echo "Extracting nginx-1.9.9.tar.gz"
tar xvzf "$SOURCES_FOLDER/nginx-1.9.9.tar.gz" -C "$SOURCES_FOLDER"

########################################################
# echo "Copmpiling Mod Security For Nginx"
# cd "$SOURCES_FOLDER/modsecurity-2.9.1/"
# ./autogen.sh
# ./configure --enable-standalone-module --disable-mlogc
# make

cd "$SOURCES_FOLDER/nginx-1.9.9"

echo "Copmpiling Nginx"
./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx     \
        --conf-path=/etc/nginx/nginx.conf     \
        --with-debug \
        --with-pcre-jit --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_addition_module \
        --with-http_dav_module \
        --with-http_geoip_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_image_filter_module \
        --with-http_v2_module \
        --with-http_sub_module \
        --with-http_xslt_module \
        --with-mail \
        --with-mail_ssl_module \
        --add-module="$SOURCES_FOLDER/modsecurity-2.8.0/nginx/modsecurity" \
        --add-module="$SOURCES_FOLDER/lua-nginx-module" \
        --add-module="$SOURCES_FOLDER/ngx_devel_kit" \
        --add-module="$SOURCES_FOLDER/set-misc-nginx-module" \
        --with-ld-opt=-Wl,-E \

make
make install

########################################################
echo "Copying Restrict IP in Lua"
cp -vR "$SOURCES_FOLDER/restrictip-lua/lua" /etc/nginx/conf.d/
