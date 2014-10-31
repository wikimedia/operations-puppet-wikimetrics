# == Class wikimetrics::web::daemon
#
class wikimetrics::web::daemon($ensure = 'present')
{
    Class['wikimetrics'] -> Class['wikimetrics::web::daemon']

    $mode             = 'web'
    $config_directory = $::wikimetrics::config_directory
    $wikimetrics_path = $::wikimetrics::path
    $service_start_on = $::wikimetrics::service_start_on

    # symlink to the public directory so that
    # flask can still serve requests from the working
    # directory (i.e. $::wikimerics::path).
    file { "${::wikimetrics::path}/wikimetrics/static/public":
        ensure => 'link',
        target => $::wikimetrics::public_directory,
    }

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
        require    => File["${::wikimetrics::path}/wikimetrics/static/public"],
        subscribe  => [
            File['/etc/init/wikimetrics-web.conf'],
            File["${config_directory}/web_config.yaml"],
            File["${config_directory}/queue_config.yaml"],
            File["${config_directory}/db_config.yaml"],
        ],
    }
}
