#!/usr/bin/env perl
package TestFor::Log4perl::useimport::resurrect;
use Test::MT::Logger::Log4perl::useimport;
use parent qw( Test::MT::Logger::Log4perl::useimport );

use MT::Logger::Log4perl qw( :resurrect );

__PACKAGE__->has(qw( resurrect ));

sub is_resurrected {
    ###l4p return 1;
    return 0
}

done_testing();

1;