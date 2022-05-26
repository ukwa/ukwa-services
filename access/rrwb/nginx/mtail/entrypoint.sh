#!/bin/sh

# Hook log files to stdout/stderr
#ln -sf /dev/stdout /var/log/nginx/access.log
#ln -sf /dev/stderr /var/log/nginx/error.log

# Start mtail in the background:
/opt/mtail/mtail -progs /opt/mtail/progs -logs /var/log/nginx/access.log &

# Start NGINX
nginx -g 'daemon off;'
