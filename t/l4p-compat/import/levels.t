#!/usr/bin/env perl
package TestFor::Log4perl::useimport::levels;
use parent qw( Test::MT::Logger::Log4perl::useimport );
use Test::More;

use ok qw( MT::Logger::Log4perl :levels );

__PACKAGE__->has(qw( levels ));



sub is_resurrected { ###l4p return 1;
    return 0       }

done_testing();

1;