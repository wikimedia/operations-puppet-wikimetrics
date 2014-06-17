# == Class wikimetrics::scheduler
#
# Starts redis-server and  wikimetrics-scheduler mode 
# which, in turn, starts celery in scheduler mode
# This class does not currently support running a redis instance
# on a different node than the wikimetrics-queue service.
#
# This class depends on the redis module.
#
class wikimetrics::scheduler
{
    require ::wikimetrics
    require ::wikimetrics::queue

    $mode             = 'scheduler'
    $config_directory = $::wikimetrics::config_directory
    $wikimetrics_path = $::wikimetrics::path
    $service_start_on = $::wikimetrics::service_start_on

    # install upstart init file
    file { '/etc/init/wikimetrics-scheduler.conf':
        content => template('wikimetrics/upstart.wikimetrics.conf.erb'),
        require => Class['::wikimetrics'],
    }

    service { 'wikimetrics-scheduler':
        ensure     => 'running',
        provider   => 'upstart',
        hasrestart => true,
        subscribe  => [
            File['/etc/init/wikimetrics-scheduler.conf'],
            File["${config_directory}/queue_config.yaml"],
            File["${config_directory}/db_config.yaml"],
            File["${config_directory}/web_config.yaml"],
        ],
    }
}
