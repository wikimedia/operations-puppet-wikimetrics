# == Class wikimetrics::queue
#
# Starts redis-server and the wikimetrics-queue service.
# This class does not currently support running a redis instance
# on a different node than the wikimetrics-queue service.
#
# This class depends on the redis module.
#
class wikimetrics::queue
{
    require ::wikimetrics

    # TODO: Why is this not working? I don't want to use the above require
    # Class['wikimetrics'] -> Class['wikimetrics::queue']

    # Install and set up redis using the redis module.
    include ::redis

    $mode = 'queue'
    $config_directory = $wikimetrics::config_directory
    $wikimetrics_path = $wikimetrics::path
    # install upstart init file
    file { '/etc/init/wikimetrics-queue.conf':
        content => template('wikimetrics/upstart.wikimetrics.conf.erb'),
        require => Class['::wikimetrics'],
    }

    service { 'wikimetrics-queue':
        ensure     => 'running',
        provider   => 'upstart',
        hasrestart => true,
        require    => Class['::redis'],
        subscribe  => [
            File['/etc/init/wikimetrics-queue.conf'],
            File['/etc/wikimetrics/queue_config.yaml'],
            File['/etc/wikimetrics/db_config.yaml'],
            File['/etc/wikimetrics/web_config.yaml'],
        ],
    }
}
