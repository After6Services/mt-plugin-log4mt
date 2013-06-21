#!/usr/bin/env perl
package TestFor::Log4perl::useimport::nowarn;
use parent qw( Test::MT::Logger::Log4perl::useimport );

use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
# use Carp::Always;

use ok qw( MT::Logger::Log4perl :nowarn );

__PACKAGE__->has(qw( nowarn ));

sub is_resurrected { ###l4p return 1;
    return 0       }

done_testing();

1;