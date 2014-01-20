# == Class wikimetrics
# Installs and configures wikimetrics.
# Note that this does not install wikimetrics dependencies.
# Use wikimetrics/scripts/install in the wikimetrics codebase
# to do so.
#
# == Parameters
# path in which to install wikimetrics
# $path                  - Path in which to clone wikimetrics.
#                          Default: /vagrant/wikimetrics
# $user                  - User to create and run wikimetrics as.
#                          Default: wikimetrics
# $group                 - wikimetrics user group.
#                          Default: wikimetrics
# $repository_owner      - owner username of the cloned wikimetrics repository.
#                          This will default to $wikimetrics::user if it is not set.
# $debug                 - Run wikimetrics in debug mode.  Default: true
#
# $celery_broker_url     - celery broker url.  Should be redis server URL.
#                          Default: redis://localhost:6379/0
# $celery_result_url     - celery result url.  Should be redis server URL.
#                          Default: redis://localhost:6379/0
#
# $server_name           - VirtualHost ServerName of wikimetrics webserver.
#                          Default: localhost
# $server_port           - VirtualHost listen port of wikimetrics webserver.
#                          Default 5000
# $ssl_redirect          - If true, site is expected to be served via HTTPS.
#                          Default: false.  THIS IS NOT YET SUPPORTED!
# $server_aliases        - Array of VirtualHost ServerAliases.  Default: undef
#
# $flask_secret_key      - Flask login secret key.  This is arbitrary.
# $meta_mw_consumer_key  - Mediawiki OAuth consumer key.
# $meta_mw_client_secret - Mediawiki OAuth client secret.
# $google_client_secret  - Google Auth client secret
# $google_client_email   - Google Auth client email address
# $google_client_id      - Google Auth client ID.
#
# $db_user_wikimetrics   - username of wikimetrics database user.  Default: wikimetrics
# $db_pass_wikimetrics   - password of wikimetrics database user.  Default: wikimetrics
# $db_name_wikimetrics   - name of wikimetrics database.           Default: wikimetrics
# $db_host_wikimetrics   - hostname of wikimetrics database.       Default: localhost
#
# $db_user_mediawiki     - Mediawiki database username.  Default: wikimetrics
# $db_pass_mediawiki     - Mediawiki database password.  Default: wikimetrics
# $db_host_mediawiki     - Mediawiki database host.
#                          In labs, you will want to use '{0}.labsdb'.
#                          Default: localhost
# $db_name_mediawiki     - Mediawiki database name.
#                          In labs, you will want to use '{0}_p'.
#                          Default: wiki
# $revision_tablename    - Name of revision table in mediawiki database.
#                          Set this only if you need to set a
#                          custom revision tablename.  In
#                          labs, you will probably want 'revision_userindex',
#                          otherwise, probably just 'revision'.  Default: undef.
#
# $config_directory      - Config directory for wikimetrics .yaml config files.
#                          Default: /etc/wikimetrics
#
class wikimetrics(
    # path in which to install wikimetrics
    $path                  = '/srv/wikimetrics',
    $user                  = 'wikimetrics',
    $group                 = 'wikimetrics',

    # owner username of the cloned wikimetrics repository.
    # This will default to $wikimetrics::user if it is not set.
    $repository_owner      = undef,

    $debug                 = true,

    $celery_broker_url     = 'redis://localhost:6379/0',
    $celery_result_url     = 'redis://localhost:6379/0',

    $server_name           = 'localhost',
    $server_port           = 5000,
    $server_aliases        = undef,
    # TODO: This is not yet supported.
    $ssl_redirect          = false,

    $flask_secret_key      = 'flask_secret_key',  # this is arbitrary
    $meta_mw_consumer_key  = 'bad4e459823278bdffb5ecf0a206112d',
    $meta_mw_client_secret = 'e312699be56f1d157657727a87ce3776e172501a',
    $google_client_secret  = 'zKv0Qg7Zr6L3Q3CaWnIuVX4B',
    $google_client_email   = '133082872359@developer.gserviceaccount.com',
    $google_client_id      = '133082872359.apps.googleusercontent.com',

    $db_user_wikimetrics   = 'wikimetrics',
    $db_pass_wikimetrics   = 'wikimetrics',
    $db_name_wikimetrics   = 'wikimetrics',
    $db_host_wikimetrics   = 'localhost',

    # Mediawiki Database Creds
    $db_user_mediawiki     = 'wikimetrics',
    $db_pass_mediawiki     = 'wikimetrics',
    $db_host_mediawiki     = 'localhost',
    $db_name_mediawiki     = 'wiki',

    $revision_tablename    = undef,

    $config_directory      = '/etc/wikimetrics',
)
{
    if !defined(Group[$group]) {
        group { $group:
          ensure => present,
          system => true,
        }
    }

    if !defined(User[$user]) {
        user { $user:
            ensure     => present,
            gid        => $group,
            home       => $path,
            managehome => false,
            system     => true,
            require    => Group[$group],
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
        ensure => 'directory',
    }

    # db_config, queue_config, web_config
    file { "${config_directory}/db_config.yaml":
        content => template('wikimetrics/db_config.yaml.erb'),
    }
    file { "${wikimetrics::config_directory}/queue_config.yaml":
        content => template('wikimetrics/queue_config.yaml.erb')
    }
    file { "${wikimetrics::config_directory}/web_config.yaml":
        content => template('wikimetrics/web_config.yaml.erb')
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
