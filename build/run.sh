#!/bin/sh

busybox httpd -h /public -p ${PORT} -f
