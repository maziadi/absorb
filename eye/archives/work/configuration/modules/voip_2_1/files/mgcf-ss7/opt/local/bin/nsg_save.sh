#!/bin/sh

rm /root/nsg_save.tgz
tar -czf /root/nsg_save.tgz /usr/local/nsg/conf /usr/local/nsg/nginx/html/php/sqlite/
