# == Class wikimetrics::web
# Wrapper for wikimetrics::web::* classes.
# == Parameters
# $mode             - Either 'apache' or 'daemon'.
#                     Use 'daemon' in development environment
#
class wikimetrics::web($mode = 'apache')
{
    # Conditionally ensure that the correct
    # web mode class is used.
    # These classes know how to ensure => absent,
    # so we include them both here with the
    # relevant ensure set for them.
    # We also, require the class with ensure =>
    # absent before the class with ensure => present,
    # so as to be sure the unwanted service is shut down
    # before the desired one is started.
    if $mode == 'apache' {
        $apache_ensure = 'present'
        $daemon_ensure = 'absent'

        $apache_require = '::wikimetrics::web::daemon'
        $daemon_require = '::wikimetrics'
    }
    else {
        $apache_ensure = 'absent'
        $daemon_ensure = 'present'

        $apache_require = '::wikimetrics'
        $daemon_require = '::wikimetrics::web::apache'
    }

    class { '::wikimetrics::web::apache':
        ensure  => $apache_ensure,
        require => Class[$apache_require],
    }
    class { '::wikimetrics::web::daemon':
        ensure  => $daemon_ensure,
        require => Class[$daemon_require],
    }
}
