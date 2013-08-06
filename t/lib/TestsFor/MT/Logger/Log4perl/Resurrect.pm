#!/usr/local/bin/perl
{
    package TestsFor::MT::Logger::Log4perl::variant::Resurrect;

    use MT::Logger::Log4perl qw( :resurrect );

    use Test::Class::Moose
        extends => 'TestsFor::MT::Logger::Log4perl';

    ###l4p has '+resurrect' => (
    ###l4p     is      => 'ro',
    ###l4p     default => 1,
    ###l4p );

    sub test_startup {
       my ( $test, $report ) = @_;
       $test->next::method;

       delete $ENV{LOG4MT_CONFIG};
       delete $ENV{MT_HOME};

    }

    sub test_resurrect_import  : Tags( compat importing resurrect ) {
        my ( $test, $report ) = @_;
        is( $test->resurrect, 1, 'Resurrected: YES!' );
    }
}

1;

__END__
