#!/usr/bin/env bash
yum install squid -y
sed -i 's/http_access deny all/http_access allow all/' /etc/squid/squid.conf
cat << EOS >> /etc/squid/squid.conf
visible_hostname none
forwarded_for off
request_header_access X-FORWARDED-FOR deny all
request_header_access VIA deny all
request_header_access CACHE-CONTROL deny all
EOS
systemctl enable --now squid