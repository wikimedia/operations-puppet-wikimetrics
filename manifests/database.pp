# == Class wikimetrics::database
#
# Note that this class does not support running
# the Wikimetrics datbase on a different host than where your
# queue and web services will run.  Permissions will only be granted
# for localhost MySQL users.  You will have to grant permissions
# for remote hosts to connect to MySQL and the wikimetrics database manually.
#
# == Parameters
# $db_user        - username of wikimetrics database user.  Default: wikimetrics
# $db_pass        - password of wikimetrics database user.  Default: wikimetrics
# $db_name        - name of wikimetrics database.           Default: wikimetrics
# $db_root_user   - Name of user MySQL commands will be executed as.  Default: 'root'
# $db_root_pass   - Password for $db_root_user.  Default: no password
#
class wikimetrics::database(
    $db_user      = 'wikimetrics',
    $db_pass      = 'wikimetrics', # you should really change this one
    $db_name      = 'wikimetrics',
    $db_root_user = 'root',
    $db_root_pass = undef,
)
{
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

    # wikimetrics is going to need a wikimetrics database and user.
    exec { 'wikimetrics_mysql_create_database':
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"CREATE DATABASE ${db_name}; USE ${db_name};\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e 'SHOW DATABASES' | /bin/grep -q ${db_name}",
        user    => 'root',
    }
    exec { 'wikimetrics_mysql_create_user':
        command => "/usr/bin/mysql ${username_option} ${password_option} -e \"
CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
CREATE USER '${db_user}'@'127.0.0.1' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;\"",
        unless  => "/usr/bin/mysql ${username_option} ${password_option} -e \"SHOW GRANTS FOR '${db_user}'@'127.0.0.1'\" | grep -q \"TO '${db_user}'\"",
        user    => 'root',
    }
}
