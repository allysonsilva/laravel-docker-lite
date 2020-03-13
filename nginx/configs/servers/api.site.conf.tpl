map $http_origin $allow_cors {
    # Indicates all map values are hostnames and should be parsed as such
    hostnames;

    default 'false';

    # All your domains
    localhost 'true';
    {{API_SITE_DOMAIN}} 'true';
}

server {

    set $phpfpm_server api-site:9000;

    set $skip_cache 1;
    set $cache_zone off;

    fastcgi_cache_key "";

    # Certification location
    include snippets/ssl-certificates.conf;

    # Strong TLS + TLS Best Practices
    include snippets/ssl.conf;

    # server listen (HTTPS)
    listen 443 ssl http2;

    server_name {{API_SITE_DOMAIN}};

    root {{API_SITE_SRC}}/public;

    location / {
        try_files $uri $uri/ /index.php?$query_string =404;

        #### Simple DDoS Defense / LIMITS
        #### Control Simultaneous Connections
        limit_conn conn_limit_per_ip 10;
        limit_req zone=req_limit_per_ip burst=100 nodelay;

        # Sets the status code to return in response to rejected requests.
        #
        # (Default: limit_conn_status 503;)
        # (Context: http, server, location)
        limit_conn_status 503;

        # Sets the status code to return in response to rejected requests.
        #
        # (Default: limit_req_status 503;)
        # (Context: http, server, location)
        limit_req_status 429;

        # if ($allow_cors = 'true') {
        #     add_header 'Access-Control-Allow-Origin' "$http_origin" always;
        #     add_header 'Access-Control-Allow-Credentials' 'true' always;
        #     add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        #     add_header 'Access-Control-Allow-Headers' 'Accept, Authorization, Content-Type , Origin, X-Requested-With' always;
        # }

        # add_header Cache-Control "no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0";

        # # Security HTTP Headers
        # include nginx.d/10-security-headers.conf;
    }

    # Several logs can be specified on the same level.
    error_log /var/log/nginx/{{API_SITE_DOMAIN}}.error.log warn;

    # Sets the path, format, and configuration for a buffered log write.
    access_log /var/log/nginx/{{API_SITE_DOMAIN}}.access.log performance;

    include snippets/deny.conf;
    include snippets/php-fpm.conf;
    include snippets/no-caching.conf;
}
