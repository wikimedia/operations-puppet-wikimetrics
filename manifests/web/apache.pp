# == Class wikimetrics::web::apache
# Installs an Apache VirtualHost to run
# wikimetrics web mode inside of Apache WSGI.
#
class wikimetrics::web::apache($ensure = 'present')
{
    Class['::wikimetrics'] -> Class['::wikimetrics::web::apache']

    $site           = 'wikimetrics'
    $docroot        = "${::wikimetrics::path}/wikimetrics"
    $server_name    = $::wikimetrics::server_name
    $server_port    = $::wikimetrics::server_port
    $server_aliases = $::wikimetrics::server_aliases
    $ssl_redirect   = $::wikimetrics::ssl_redirect

    if !defined(Package['libapache2-mod-wsgi']) {
        package { 'libapache2-mod-wsgi':
            ensure => 'installed',
        }
    }
    if !defined(Apache::Mod['wsgi']) {
        apache::mod { 'wsgi':
            require => Package['libapache2-mod-wsgi'],
        }
    }
    # we only need mod rewrite if $ssl_redirect is true
    if $ssl_redirect and !defined(Apache::Mod['rewrite']) {
        apache::mod { 'rewrite':
            before => Exec["apache_enable_${site}"],
        }
    }

    file { "/etc/apache2/sites-available/${site}":
        ensure  => $ensure,
        content => template('wikimetrics/wikimetrics.vhost.erb'),
        require => [Package['apache2'], Apache::Mod['wsgi']],
    }

    # disable if sites-enabled symlink exists and ensure is absent
    if ($ensure == 'absent') {
        exec { "apache_disable_${site}":
            command   => "a2dissite -qf ${site}",
            onlyif    => "test -L /etc/apache2/sites-enabled/${site}",
            notify    => Service['apache2'],
            require   => Package['apache2'],
            before    => File["/etc/apache2/sites-available/${site}"],
        }
    }
    # otherwise enable the site!
    else {
        exec { "apache_enable_${site}":
            command   => "a2ensite -qf ${site}",
            unless    => "test -L /etc/apache2/sites-enabled/${site}",
            notify    => Service['apache2'],
            require   => Package['apache2'],
            subscribe => [
                File["/etc/apache2/sites-available/${site}"],
                File["${::wikimetrics::config_directory}/web_config.yaml"],
                File["${::wikimetrics::config_directory}/queue_config.yaml"],
                File["${::wikimetrics::config_directory}/db_config.yaml"],
            ],
        }
    }
}
