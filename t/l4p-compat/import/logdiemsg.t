#!/usr/bin/env perl
package TestFor::Log4perl::useimport::no_extra_logdie_message;
use parent qw( Test::MT::Logger::Log4perl::useimport );

use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
# use Carp::Always;

use ok qw( MT::Logger::Log4perl :no_extra_logdie_message );

__PACKAGE__->has(qw( no_extra_logdie_message ));


sub is_resurrected { ###l4p return 1;
    return 0       }

done_testing();

1;
