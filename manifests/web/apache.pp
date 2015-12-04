# == Class wikimetrics::web::apache
# Installs an Apache VirtualHost to run
# wikimetrics web mode inside of Apache WSGI.
#
class wikimetrics::web::apache($ensure = 'present')
{
    Class['::wikimetrics'] -> Class['::wikimetrics::web::apache']

    $config_directory  = $::wikimetrics::config_directory
    $public_directory  = $::wikimetrics::public_directory
    $site              = 'wikimetrics'
    $docroot           = "${::wikimetrics::path}/wikimetrics"
    $server_name       = $::wikimetrics::server_name
    $server_port       = $::wikimetrics::server_port
    $server_aliases    = $::wikimetrics::server_aliases
    $ssl_redirect      = $::wikimetrics::ssl_redirect

    include ::apache
    include ::apache::mod::wsgi
    include ::apache::mod::rewrite
    include ::apache::mod::headers
    include ::apache::mod::expires


    file { "/etc/apache2/sites-available/${site}":
        ensure  => $ensure,
        content => template('wikimetrics/wikimetrics.vhost.erb'),
        require => Class['::apache::mod::wsgi'],
    }

    # disable if sites-enabled symlink exists and ensure is absent
    if ($ensure == 'absent') {
        exec { "apache_disable_${site}":
            command => "/usr/sbin/a2dissite -qf ${site}",
            onlyif  => "/usr/bin/test -L /etc/apache2/sites-enabled/${site}",
            notify  => Service['apache2'],
            require => Package['apache2'],
            before  => File["/etc/apache2/sites-available/${site}"],
        }
    }
    # otherwise enable the site!
    else {
        exec { "apache_enable_${site}":
            command   => "/usr/sbin/a2ensite -qf ${site}",
            unless    => "/usr/bin/test -L /etc/apache2/sites-enabled/${site}",
            notify    => Service['apache2'],
            require   => Package['apache2'],
            subscribe => [
                File["/etc/apache2/sites-available/${site}"],
                File["${config_directory}/web_config.yaml"],
                File["${config_directory}/queue_config.yaml"],
                File["${config_directory}/db_config.yaml"],
            ],
        }
    }
}
