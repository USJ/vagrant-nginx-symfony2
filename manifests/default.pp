class nginx-php-mongo {
	include nodejs

	host {'self':
		ensure       => present,
		name         => $fqdn,
		host_aliases => ['puppet', $hostname],
		ip           => $ipaddress,
	}
	
	$php = ["php5-fpm", "php5-cli", "php5-dev", "php5-gd", "php5-curl", "php-pear", "php-apc", "php5-mcrypt", "php5-xdebug", "php5-sqlite"]
	
	$imagemagicklib = ["imagemagick","libmagickwand-dev","libmagickcore-dev"]

	$util = ["curl", "git", "wget"]

	apt::ppa { "ppa:ondrej/php5":
		before => [Package[$php], Package[$util], Package["openjdk-7-jre-headless"], Package["nginx"], Package["mongodb"], Package[$imagemagicklib] ]
	}

	package { $util:
		ensure => present,
	}

	package { "openjdk-7-jre-headless":
		ensure => present,
	}

	package { "build-essential":
		ensure => present,
	}
	
	package { "nginx":
		ensure => present,
	}
	
	package { "mongodb":
		ensure => present,
	}

	package { $imagemagicklib:
		ensure => present,
	}

	package { $php:
		notify => Service['php5-fpm'],
		ensure => latest,
	}

	exec { 'apt-update' : 
		command => '/usr/bin/apt-get update',
		before => Package["python-software-properties"]
	}

	package { 'php5-imagick':
		notify => Service["php5-fpm"],
		require => [Package["libmagickwand-dev"], Package["libmagickcore-dev"],Package[$php]],
		before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
	}
	
	exec { 'pecl install mongo':
		notify => Service["php5-fpm"],
		command => '/usr/bin/pecl install --force mongo-1.3.3',
		logoutput => "on_failure",
		require => [Package["build-essential"], Package[$php]],
		before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
		unless => "/usr/bin/php -m | grep mongo",
	}
	
	exec { 'pear config-set auto_discover 1':
		command => '/usr/bin/pear config-set auto_discover 1',
		before => Exec['pear install pear.phpunit.de/PHPUnit'],
		require => Package[$php],
		unless => "/bin/ls -l /usr/bin/ | grep phpunit",
	}
	
	exec { 'pear install pear.phpunit.de/PHPUnit':
		notify => Service["php5-fpm"],
		command => '/usr/bin/pear install --force pear.phpunit.de/PHPUnit',
		before => [File['/etc/php5/cli/php.ini'], File['/etc/php5/fpm/php.ini'], File['/etc/php5/fpm/php-fpm.conf'], File['/etc/php5/fpm/pool.d/www.conf']],
		unless => "/bin/ls -l /usr/bin/ | grep phpunit",
	}

    exec { 'gem update --system':
        command => '/opt/vagrant_ruby/bin/gem update --system'
    }

    exec { 'gem install compass':
        command => '/opt/vagrant_ruby/bin/gem install compass',
        require => Exec['gem update --system']
    }

    package { 'less':
      ensure   => present,
      provider => 'npm',
    }

	file { '/etc/php5/cli/php.ini':
		owner  => root,
		group  => root,
		ensure => file,
		mode   => 644,
		source => '/vagrant/files/php/cli/php.ini',
		require => Package[$php],
	}
	
	file { '/etc/php5/fpm/php.ini':
		notify => Service["php5-fpm"],
		owner  => root,
		group  => root,
		ensure => file,
		mode   => 644,
		source => '/vagrant/files/php/fpm/php.ini',
		require => Package[$php],
	}
	
	file { '/etc/php5/fpm/php-fpm.conf':
		notify => Service["php5-fpm"],
		owner  => root,
		group  => root,
		ensure => file,
		mode   => 644,
		source => '/vagrant/files/php/fpm/php-fpm.conf',
		require => Package[$php],
	}
	
	file { '/etc/php5/fpm/pool.d/www.conf':
		notify => Service["php5-fpm"],
		owner  => root,
		group  => root,
		ensure => file,
		mode   => 644,
		source => '/vagrant/files/php/fpm/pool.d/www.conf',
		require => Package[$php],
	}
	
	file { '/etc/nginx/sites-available/default':
		owner  => root,
		group  => root,
		ensure => file,
		mode   => 644,
		source => '/vagrant/files/nginx/default',
		require => Package["nginx"],
	}
	
	file { "/etc/nginx/sites-enabled/default":
		notify => Service["nginx"],
		ensure => link,
		target => "/etc/nginx/sites-available/default",
		require => Package["nginx"],
	}

	
	service { "php5-fpm":
	  ensure => running,
	  require => Package["php5-fpm"],
	}
	
	service { "nginx":
	  ensure => running,
	  require => Package["nginx"],
	}
	
	service { "mongodb":
	  ensure => running,
	  require => Package["mongodb"],
	}

	service { "apache2":
		ensure => stopped,
		notify => Service["nginx"],
		require => [Package["nginx"],Package["php5-fpm"]]
	}


}
	
include nginx-php-mongo
