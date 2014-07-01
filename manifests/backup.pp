# == Class wikimetrics::backup
#
# Backs up wikimetrics files to a specified path
#
# == Parameters
# $destination      - path to copy backup files to.  Should be unique within a
#                     labs project, otherwise it might overwrite other backups.  Required
# $user             - user to coordinate the backup.  Default 'root'
# $group            - group of the coordinating user.  Default 'root'
# $db_user          - username of wikimetrics database user.  Default 'wikimetrics'
# $db_pass          - password of wikimetrics database user.  Default 'wikimetrics'
# $db_name          - database to back up.  Default 'wikimetrics'
# $db_host          - hostname of wikimetrics database. Default 'localhost'
# $redis_db_file    - redis database file.  Default '/a/redis/wikimetrics1-6379.rdb',
# $public_files     - directory where public files (mostly reports) are.
#                     This directory has to exist, and it should match
#                     the value that ::wikimetrics sets.
#                     Default '/var/lib/wikimetrics/public'
# $keep_days        - How many days of history to keep.  Default 10
# $ensure           - Either 'present', or 'absent'. 'absent' does only remove
#                     scripts, configs, and cronjobs but not previously made
#                     backups. Default 'present'
#
class wikimetrics::backup(
    $destination,
    $user           = 'root',
    $group          = 'root',
    $db_user        = 'wikimetrics',
    $db_pass        = 'wikimetrics',
    $db_name        = 'wikimetrics',
    $db_host        = 'localhost',
    $redis_db_file  = "/a/redis/${hostname}-6379.rdb",
    $public_files   = '/var/lib/wikimetrics/public',
    $keep_days      = 10,
    $ensure         = present,
)
{

    $hourly_destination = "${destination}/hourly"
    $daily_destination  = "${destination}/daily"
    $backup_hourly_script = "${destination}/hourly_script"
    $backup_daily_script  = "${destination}/daily_script"
    $mysql_defaults_file = "${destination}/my.cnf"

    # Manage destination directories only if we are running the backups.
    # This allows to ensure => absent wikimetrics::backup on old
    # instances and still keep the made backups around.
    if $ensure == 'present' {
        # These directories should be writable by $user and $group.
        file { [$destination, $hourly_destination, $daily_destination]:
            ensure  => 'directory',
            owner   => $user,
            group   => $group,
            mode    => '0700',
        }
    }

    file { $backup_daily_script:
        ensure  => $ensure,
        source  => 'puppet:///modules/wikimetrics/backup/daily_script',
        owner   => $user,
        group   => $group,
        mode    => '0555',
    }

    file { $backup_hourly_script:
        ensure  => $ensure,
        source => 'puppet:///modules/wikimetrics/backup/hourly_script',
        owner   => $user,
        group   => $group,
        mode    => '0555',
    }

    file { $mysql_defaults_file:
        ensure  => $ensure,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        content => "# This file is managed by puppet.

[client]
user=${db_user}
password=${db_pass}
host=${db_host}
default-character-set=utf8
",
    }

    # backs up wikimetrics essentials hourly, overwriting the previous backup
    cron { 'hourly wikimetrics backup':
        ensure   => $ensure,
        command  => "${backup_hourly_script} -o ${hourly_destination} -f ${public_files} -d ${db_name} -m ${mysql_defaults_file} -r ${redis_db_file}",
        user     => $user,
        minute   => 0,
    }

    # backs up wikimetrics essentials daily, keeping the last $keep_days days
    cron { 'daily wikimetrics backup':
        ensure   => $ensure,
        command  => "${backup_daily_script} -i ${hourly_destination} -o ${daily_destination} -k ${keep_days}",
        user     => $user,
        hour     => 22,
        minute   => 30,
    }
}
