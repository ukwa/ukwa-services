# Common redirects to support the original URLs, included in other configs:
location /welcome.html {
    # Strip any /welcome.html, converting query string to path:
    set $new_path $args;
    set $args '';
    rewrite ^/(.*)$ /$new_path last;
    # Also need 'npld_access_staff_autostart.html?' ?
}
location / {

    # Explicit ARKs
    rewrite ^/ark:/(\d+)/([^\/]+) /doc/20130401000000/http://doc-streamer:8000/ark:/$1/$2/ permanent;
    
    # Implied ARKs (starting with e.g. vdc_)
    rewrite ^/(vd[^\/]+) /doc/20130401000000/http://doc-streamer:8000/ark:/81055/$1/ permanent;

    # UKWA IDs e.g. TIMESTAMP/URL:
    rewrite ^/(\d+)/(.*)$ /web/$1/$2 permanent;
}