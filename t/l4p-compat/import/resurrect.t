#!/usr/bin/env perl
package TestFor::Log4perl::useimport::resurrect;
BEGIN {
    # use ok qw( MT::Logger::Log4perl :resurrect );
    # use_ok( 'MT::Logger::Log4perl', qw( :resurrect ));
    use MT::Logger::Log4perl qw( :resurrect );
}
use Test::More;
our @ISA = 
use parent -norequire qw( Test::MT::Logger::Log4perl::useimport );



__PACKAGE__->has(qw( resurrect ));


sub is_resurrected { ###l4p return 1;
    return 0       }

done_testing();

1;