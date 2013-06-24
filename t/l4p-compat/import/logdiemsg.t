#!/usr/bin/env perl
package TestFor::Log4perl::useimport::no_extra_logdie_message;
use Test::MT::Logger::Log4perl::useimport;
use parent qw( Test::MT::Logger::Log4perl::useimport );

use MT::Logger::Log4perl qw(:no_extra_logdie_message );

__PACKAGE__->has(qw( no_extra_logdie_message ));

sub is_resurrected {
    ###l4p return 1;
    return 0
}

done_testing();

1;
