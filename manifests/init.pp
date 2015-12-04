# == Class wikimetrics
# Installs and configures wikimetrics.
# Note that this does not install wikimetrics dependencies.
# Use wikimetrics/scripts/install in the wikimetrics codebase
# to do so.
#
# == Parameters
# path in which to install wikimetrics
# $path                         - Path in which to clone wikimetrics.
#                                 Default: /srv/wikimetrics
# $user                         - wikimetrics user, wikimetrics will run as this
#                                 user. Directories that need to be written by
#                                 wikimetrics will be writeable by this user.
# $group                        - wikimetrics group, wikimetrics will run as
#                                 this group. Directories that need to be
#                                 written by wikimetrics will be writeable by
#                                 this group.
# $repository_owner             - owner username of the cloned wikimetrics
#                                 repository. This will default to
#                                 $wikimetrics::user if it is not set.
# $debug                        - Run wikimetrics in debug mode.  Default: true
#
# $celery_broker_url            - celery broker url.  Should be redis server
#                                 URL.
#                                 Default: redis://localhost:6379/0
# $celery_result_url            - celery result url.  Should be redis server
#                                 URL.
#                                 Default: redis://localhost:6379/0
#
# $celery_concurrency           - celery queue concurrency.
#                                 Default: 16
# $server_name                  - VirtualHost ServerName of wikimetrics
#                                 webserver.
#                                 Default: localhost
# $server_port                  - VirtualHost listen port of wikimetrics
#                                 webserver.
#                                 Default 5000
# $ssl_redirect                 - If true, site is expected to be served via
#                                 HTTPS.
#                                 Default: false.  THIS IS NOT YET SUPPORTED!
# $server_aliases               - Array of VirtualHost ServerAliases.
#                                 Default: undef
#
# $flask_secret_key             - Flask login secret key.  This is arbitrary.
# $meta_mw_consumer_key         - Mediawiki OAuth consumer key.
# $meta_mw_client_secret        - Mediawiki OAuth client secret.
# $google_client_secret         - Google Auth client secret
# $google_client_email          - Google Auth client email address
# $google_client_id             - Google Auth client ID.
#
# $db_user_wikimetrics          - username of wikimetrics database user.
#                                 Default: wikimetrics
# $db_pass_wikimetrics          - password of wikimetrics database user.
#                                 Default: wikimetrics
# $db_name_wikimetrics          - name of wikimetrics database.
#                                 Default: wikimetrics
# $db_host_wikimetrics          - hostname of wikimetrics database.
#                                 Default: localhost
# $db_pool_wikimetrics          - pool size for wikimetrics database.
#                                 Default: 20
#
# $db_user_mediawiki            - Mediawiki database username. Just require.
# $db_pass_mediawiki            - Mediawiki database password. Just require.
# $db_host_mediawiki            - Mediawiki database host.
#                                 In labs, you will want to use '{0}.labsdb'.
#                                 Default: localhost
# $db_name_mediawiki            - Mediawiki database name.
#                                 In labs, you will want to use '{0}_p'.
#                                 Default: wiki
# $db_pool_mediawiki            - Mediawiki pool size.
#                                 Default: 32
# $db_replication_lag_dbs       - List of dbs to check for lag.
#                                 Default: []
# $db_replication_lag_threshold - Consider a database lagged, is there was no
#                                 edit in that many hours.
#                                 Default: 3
# $db_user_centralauth          - Centralauth database username. Just require.
# $db_pass_centralauth          - Centralauth database password. Just require.
# $db_host_centralauth          - Centralauth database host.
#                                 Default: localhost
# $db_name_centralauth          - Centralauth database name.
#                                 Default: centralauth
# $revision_tablename           - Name of revision table in mediawiki database.
#                                 Set this only if you need to set a custom
#                                 revision tablename.  In labs, you will
#                                 probably want 'revision_userindex', otherwise,
#                                 probably just 'revision'.  Default: undef.
# $archive_tablename            - Name of archive table in mediawiki database.
#                                 Set this only if you need to set a
#                                 custom archive tablename.  In
#                                 labs, you will probably want 'archive_userindex',
#                                 otherwise, probably just 'archive'.  Default: undef.
#
# $config_directory             - Config directory for wikimetrics .yaml config
#                                 files.
#                                 Default: /etc/wikimetrics
# $config_file_owner            - User ownership of wikimetrics .yaml config
#                                 files.
#                                 Default: root
# $config_file_group            - Group ownership of wikimetrics .yaml config
#                                 files.
#                                 Default: root
# $service_start_on             - start on stanza for upstart jobs (queue, web
#                                 daemon).
#                                 Default: started network-services
# $public_subdirectory          - Directory for public reports in
#                                 $var_directory. Must not contain slashes.
#                                 Default: public
class wikimetrics(
    # path in which to install wikimetrics
    $path                         = '/srv/wikimetrics',

    # wikimetrics will run as this user and group
    $user                         = 'wikimetrics',
    $group                        = 'wikimetrics',

    # owner username of the cloned wikimetrics repository.
    # This will default to $wikimetrics::user if it is not set.
    $repository_owner             = undef,

    $debug                        = true,

    $celery_broker_url            = 'redis://localhost:6379/0',
    $celery_result_url            = 'redis://localhost:6379/0',
    $celery_concurrency           = 10,

    $server_name                  = 'localhost',
    $server_port                  = 5000,
    $server_aliases               = undef,
    # TODO: This is not yet supported.
    $ssl_redirect                 = false,

    $flask_secret_key             = 'flask_secret_key',  # this is arbitrary
    $meta_mw_consumer_key         = 'bad4e459823278bdffb5ecf0a206112d',
    $meta_mw_client_secret        = 'e312699be56f1d157657727a87ce3776e172501a',
    $google_client_secret         = 'zKv0Qg7Zr6L3Q3CaWnIuVX4B',
    $google_client_email          = '133082872359@developer.gserviceaccount.com',
    $google_client_id             = '133082872359.apps.googleusercontent.com',

    $db_user_wikimetrics          = 'wikimetrics',
    $db_pass_wikimetrics          = 'wikimetrics',
    $db_name_wikimetrics          = 'wikimetrics',
    $db_host_wikimetrics          = 'localhost',
    $db_pool_wikimetrics          = 20,

    # Mediawiki Database Creds
    $db_user_mediawiki            ,
    $db_pass_mediawiki            ,
    $db_host_mediawiki            = 'localhost',
    $db_name_mediawiki            = 'wiki',
    $db_pool_mediawiki            = 32,
    $db_replication_lag_dbs       = [],
    $db_replication_lag_threshold = 3, # hours

    # Centralauth Database Creds
    $db_user_centralauth          ,
    $db_pass_centralauth          ,
    $db_host_centralauth          = 'localhost',
    $db_name_centralauth          = 'centralauth',

    $revision_tablename           = undef,
    $archive_tablename            = undef,

    $var_directory                = '/var/lib/wikimetrics',
    $run_directory                = '/var/run/wikimetrics',
    $config_directory             = '/etc/wikimetrics',
    $config_file_owner            = 'root',
    $config_file_group            = 'root',

    $service_start_on             = 'started network-services',

    $public_subdirectory          = 'public',
)
{
    # Although we could inline $public_directory as it is used only
    # once in this file, other wikimetrics modules
    # (e.g. wikimetrics::web::apache) directly access
    # $public_directory from here, so we cannot remove it :-(
    $public_directory = "${var_directory}/${public_subdirectory}"

    $celery_beat_datafile  = "${run_directory}/celerybeat_scheduled_tasks"
    $celery_beat_pidfile   = "${run_directory}/celerybeat.pid"

    if !defined(Group[$group]) {
        group { $group:
          ensure => 'present',
          system => true,
        }
    }
    if !defined(User[$user]) {
        user { $user:
            ensure     => 'present',
            gid        => $group,
            home       => $path,
            managehome => false,
            system     => true,
        }
    }

    $owner = $repository_owner ? {
        undef   => $user,
        default => $repository_owner,
    }
    # Clone wikimetrics from gerrit.
    git::clone { 'analytics/wikimetrics':
        directory => $path,
        owner     => $owner,
    }

    file { $config_directory:
        ensure  => 'directory',
        owner   => $config_file_owner,
        group   => $config_file_group,
        require => Git::Clone['analytics/wikimetrics'],
    }

    # These directories should be writable by $user and $group.
    file { [$var_directory, $public_directory, $run_directory ]:
        ensure  => 'directory',
        owner   => $user,
        group   => $group,
        mode    => '0775',
        require => Git::Clone['analytics/wikimetrics'],
    }

    # db_config, queue_config, web_config
    file { "${config_directory}/db_config.yaml":
        content => template('wikimetrics/db_config.yaml.erb'),
        owner   => $config_file_owner,
        group   => $config_file_group,
    }
    file { "${config_directory}/queue_config.yaml":
        content => template('wikimetrics/queue_config.yaml.erb'),
        owner   => $config_file_owner,
        group   => $config_file_group,
    }
    file { "${config_directory}/web_config.yaml":
        content => template('wikimetrics/web_config.yaml.erb'),
        owner   => $config_file_owner,
        group   => $config_file_group,
    }

    if !defined(Package['gcc']) {
        package { 'gcc': ensure => 'installed' }
    }
    if !defined(Package['python-dev']) {
        package { 'python-dev': ensure => 'installed' }
    }
    if !defined(Package['libmysqlclient-dev']) {
        package { 'libmysqlclient-dev': ensure => 'installed' }
    }

    # This class will not fully install dependencies for wikimetrics.
    # To finish the installation, you must do the following:
    #
    # Install newer pip:
    #   wget https://pypi.python.org/packages/source/p/pip/pip-1.4.1.tar.gz && tar -xvzf pip-1.4.1.tar.gz && cd pip-1.4.1 && easy_install
    #
    # Install wikimetrics dependencies
    #   cd $path; /usr/local/bin/pip install -e .
}
