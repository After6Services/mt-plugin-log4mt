#!/usr/local/bin/perl
package MT::LoggerTest;

use strict;
use warnings;
use lib qw( addons/Log4MT.plugin/lib lib extlib );
our $logger;
print "Init OK. Testing logger\n";
my $foo = { a => 1, b => 2 };


# use MT::Logger::Log4perl qw( get_logger l4mtdump :resurrect );
# ###l4p $logger = MT::Logger::Log4perl->get_logger();

# use MT::Logger::Log4perl qw( get_logger l4mtdump :resurrect );
# ###l4p $logger = get_logger();

# use Log::Log4perl qw( :resurrect );
# ###l4p use MT::Log::Log4perl qw( l4mtdump );
# ###l4p $logger ||= MT::Log::Log4perl->new();



###l4p $logger->warn('Foo: ', l4mtdump($foo));
print "Logging done\n";

1;
__END__


