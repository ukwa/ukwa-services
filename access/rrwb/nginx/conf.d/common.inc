# Common redirects to support the original URLs, included in other configs:
location / {

    # Map original service URLs to the new ones:
    rewrite ^/(welcome.html?|)ark:/(\d+)/([^\/]+) /doc/20130401000000/http://doc-streamer:8000/ark:/$2/$3/ permanent;
    rewrite ^/(welcome.html?|)(\d+)/(.*)$ /web/$2/$3 permanent;
    # Also need 'npld_access_staff_autostart.html?' ?

}