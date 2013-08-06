#!/usr/local/bin/perl
package TestFor::Log4perl::useimport::get_logger;
use Test::MT::Logger::Log4perl::useimport;
use parent qw( Test::MT::Logger::Log4perl::useimport );

use MT::Logger::Log4perl qw( get_logger );

__PACKAGE__->has(qw( get_logger ));

sub is_resurrected {
    ###l4p return 1;
    return 0
}

done_testing();

1;
