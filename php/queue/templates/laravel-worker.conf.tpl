[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php artisan queue:work {{QUEUE_CONNECTION}} --queue=high,{{REDIS_QUEUE}},low --memory={{QUEUE_MEMORY}} --env=%(ENV_APP_ENV)s --sleep={{QUEUE_SLEEP}} --tries={{QUEUE_TRIES}} --delay={{QUEUE_DELAY}} --timeout={{QUEUE_TIMEOUT}}
directory=%(ENV_REMOTE_SRC)s
autostart=true
autorestart=false
redirect_stderr=true
stdout_logfile=%(ENV_REMOTE_SRC)s/storage/logs/worker-queue.out.log
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
numprocs=6
startretries=2
user=%(ENV_USER_NAME)s
