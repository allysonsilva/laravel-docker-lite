[program:laravel-horizon]
process_name=%(program_name)s
command=php artisan horizon
directory=%(ENV_REMOTE_SRC)s
autostart=true
autorestart=false
redirect_stderr=true
stdout_logfile=%(ENV_REMOTE_SRC)s/storage/logs/horizon.out.log
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
numprocs=1
startretries=2
user=%(ENV_USER_NAME)s
