# == Define wikimetrics::database::create
# Creates the database and grants all privileges on it
# to $db_user and $db_pass.
#
# == Parameters
# $db_user                       - username of wikimetrics database user.    Default: wikimetrics
# $db_pass                       - password of wikimetrics database user.    Default: wikimetrics
# $db_root_user                  - Name of user MySQL commands will be executed as.  Default: 'root'
# $db_root_pass                  - Password for $db_root_user.  Default: no password
#
define wikimetrics::database::create(
    $db_user      = 'wikimetrics',
    $db_pass      = 'wikimetrics',
    $db_root_user = 'root',
    $db_root_pass = undef,
)
{
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
    # run mysql command to create database $title if it doesn't already exist
    exec { "wikimetrics_create_database_${title}":
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"CREATE DATABASE ${title}; USE ${title};\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e 'SHOW DATABASES' | /bin/grep -q -P '^${title}\$'",
        user    => 'root',
    }

    exec { "wikimetrics_mysql_grant_for_${title}":
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"
GRANT ALL PRIVILEGES ON ${title}.* TO '${db_user}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${title}.* TO '${db_user}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e \"
SHOW GRANTS FOR '${db_user}'@'127.0.0.1'\" | grep \"${title}.* TO '${db_user}'\"",
        user    => 'root',
        require => Exec["wikimetrics_create_database_${title}"],
    }
}
