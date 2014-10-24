#!/usr/local/bin/perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Buffer;

    use 5.008_008;
    use Test::Class::Moose;
        with 'Test::Class::Moose::Role::AutoUse';
        extends 'TestsFor::MT::Log::Log4perl::Appender::MT::Base';

    sub test_setup {}

    sub test_constructor  : Tags( appender mtbuffer ) {
        my ( $test, $report ) = @_;
        my %p = ();
        my $appender = $test->build_appender( %p );
        isa_ok( $appender, 'Log::Log4perl::Appender' );
    }

    sub test_is_mt_initialized  : Tags( appender mtbuffer ) {
        my ( $test, $report ) = @_;
        is( $test->class_name->is_mt_initialized, 0, 'MT not initialized' );
        require MT;
        my $app = MT->instance;
        is( $test->class_name->is_mt_initialized, 1, 'MT is initialized' );
    }
}
1;

__END__
