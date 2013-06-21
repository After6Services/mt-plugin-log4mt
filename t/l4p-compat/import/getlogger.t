#!/usr/bin/env perl
package TestFor::Log4perl::useimport::get_logger;
use Test::More;

use parent qw( Test::MT::Logger::Log4perl::useimport );

use ok qw( MT::Logger::Log4perl get_logger );

__PACKAGE__->has(qw( get_logger ));


sub is_resurrected { ###l4p return 1;
    return 0       }

done_testing();

1;