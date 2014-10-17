# == Class wikimetrics::database
#
# Note that this class does not support running
# the Wikimetrics datbase on a different host than where your
# queue and web services will run.  Permissions will only be granted
# for localhost MySQL users.  You will have to grant permissions
# for remote hosts to connect to MySQL and the wikimetrics database manually.
#
# == Parameters
# $db_user                       - username of wikimetrics database user.    Default: wikimetrics
# $db_pass                       - password of wikimetrics database user.    Default: wikimetrics
# $db_name_wikimetrics           - name of wikimetrics database.  Default: wikimetrics
# $db_names_testing              - name of of testing databases.  Default: ['wikimetrics_testing', 'wiki_testing', 'wiki2_testing', 'centralauth_testing']
# $db_root_user                  - Name of user MySQL commands will be executed as.  Default: 'root'
# $db_root_pass                  - Password for $db_root_user.  Default: no password
# $wikimetrics_path              - Path to wikimetrics source.  Default: '/srv/wikimetrics'
#
class wikimetrics::database(
    $db_user                     = 'wikimetrics',
    $db_pass                     = 'wikimetrics', # you should really change this one
    $db_name_wikimetrics         = 'wikimetrics',
    $db_names_testing            = [
        'wikimetrics_testing',
        'wiki_testing',
        'wiki2_testing',
        'centralauth_testing'
    ],
    $db_root_user                = 'root',
    $db_root_pass                = undef,
    $wikimetrics_path            = '/srv/wikimetrics',
)
{
    require ::wikimetrics

    # mysql-server must be installed on this node to use this class.
    Package['mysql-server'] -> Class['::wikimetrics::database']

    # Only use -u or -p flag to mysql commands if
    # root username or root password are set.
    $username_option = $db_root_user ? {
        undef   => '',
        default => "-u'${db_root_user}'",
    }
    $password_option = $db_root_pass ? {
        undef   => '',
        default => "-p'${db_root_pass}'",
    }

    # create the wikimetrics mysql user
    exec { 'wikimetrics_mysql_create_user':
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
CREATE USER '${db_user}'@'127.0.0.1' IDENTIFIED BY '${db_pass}';\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e \"
SELECT user FROM mysql.user;\" | grep -q \"${db_user}\"",
        user    => 'root',
    }

    # Make all further wikimetrics::database::create
    # uses automatically require the exec that created
    # the wikimetrics mysql user.
    Wikimetrics::Database::Create {
        require => Exec['wikimetrics_mysql_create_user'],
    }


    # Create wikimetrics database
    wikimetrics::database::create { $db_name_wikimetrics:
        db_user      => $db_user,
        db_pass      => $db_pass,
        db_root_user => $db_root_user,
        db_root_pass => $db_root_pass,
    }

    # If we are running in debug mode, then
    # go ahead and create the test databases
    if $::wikimetrics::debug {
        wikimetrics::database::create { $db_names_testing:
            db_user      => $db_user,
            db_pass      => $db_pass,
            db_root_user => $db_root_user,
            db_root_pass => $db_root_pass,
            before       => Exec['alembic_upgrade_head']
        }
    }

    # In wikimetrics.pp we are installing all deps wia pip
    # should be safe to assume alembic is installed
    # this would run only if alembic is not setup
    # as we prefer puppet not handle migrations
    exec { 'alembic_upgrade_head':
        cwd =>  $wikimetrics_path,
        command => "/usr/local/bin/alembic upgrade head",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e \"USE ${db_name_wikimetrics};SHOW tables\"| grep alembic ",
        user    => 'root',
        require => [
            Wikimetrics::Database::Create[$db_name_wikimetrics],
            Exec['wikimetrics_mysql_create_user']
        ],
    }
 }
