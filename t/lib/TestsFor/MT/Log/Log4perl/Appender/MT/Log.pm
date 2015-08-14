#!/usr/local/bin/perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Log;

    use 5.008_008;
    use Test::Class::Moose;
        extends 'TestsFor::MT::Log::Log4perl::Appender::MT::Base';
        with 'Test::Class::Moose::Role::AutoUse';

    sub test_setup  : Tags( appender mtlog ) {
        my ( $test, $report ) = @_;
        my $app = $test->build_app;
    }

    sub test_constructor  : Tags( appender mtlog ) {
        my ( $test, $report ) = @_;
        my $appender = $test->build_appender();
        isa_ok( $appender, 'Log::Log4perl::Appender', '$appender' );
    }

    sub test_log  : Tags( appender mtlog ) {
        my ( $test, $report ) = @_;
        my $mt = $test->build_app;
        require MT::Logger::Log4perl;
        import MT::Logger::Log4perl qw(get_logger);

        my $error = 'Error test';

        my $l = MT::Logger::Log4perl->get_logger();
        $l->error($error);

        my $log = $test->last_log();
        like( $log->message, qr/$error/, 'Error message is last log' );

        $l->debug('Not an error');
        $log = $test->last_log();
        like( $log->message, qr/$error/, 'Error message is still last log' );
    }
}
1;

__END__
