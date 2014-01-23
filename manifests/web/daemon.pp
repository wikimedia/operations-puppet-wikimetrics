# == Class wikimetrics::web::daemon
#
class wikimetrics::web::daemon($ensure = 'present')
{
    Class['wikimetrics'] -> Class['wikimetrics::web::daemon']

    $mode             = 'web'
    $config_directory = $wikimetrics::config_directory
    $wikimetrics_path = $wikimetrics::path

    # install upstart init file
    file { '/etc/init/wikimetrics-web.conf':
        content => template('wikimetrics/upstart.wikimetrics.conf.erb'),
        require => Class['::wikimetrics'],
    }

    $service_ensure = $ensure ? {
        'absent' => 'stopped',
        default  => 'running',
    }
    service { 'wikimetrics-web':
        ensure     => $service_ensure,
        provider   => 'upstart',
        hasrestart => true,
        subscribe  => [
            File['/etc/init/wikimetrics-web.conf'],
            File["${::wikimetrics::config_directory}/web_config.yaml"],
            File["${::wikimetrics::config_directory}/queue_config.yaml"],
            File["${::wikimetrics::config_directory}/db_config.yaml"],
        ],
    }
}
