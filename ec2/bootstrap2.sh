#!/bin/bash
sudo bash -c 'echo "${es_cluster_address}" > /usr/share/nginx/html/index.html'
systemctl restart nginx
