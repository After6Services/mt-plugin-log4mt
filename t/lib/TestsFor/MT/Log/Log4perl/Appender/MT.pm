#!/usr/bin/env perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT;

    use 5.010;
    use MT::Logger::Log4perl;
    use Test::Class::Moose;
        with 'Test::Class::Moose::Role::AutoUse';
    use Test::Fatal;
    use Data::Printer output => 'STDOUT', colored => 1;

    # sub test_startup {
    #     my ( $test, $report ) = @_;
    #     $test->test_skip("I don't want to run this class");
    # }

    sub build_appender {
        return MT::Log::Log4perl::Appender::MT->new;
    }

    sub build_app {
        require MT;
        return MT->instance();
    }

    sub test_constructor {
        my ( $test, $report ) = @_;
        my $appender = $test->build_appender;
        isa_ok( $appender, 'MT::Log::Log4perl::Appender::MT', '$appender' );
        isa_ok( $appender, 'Log::Log4perl::Appender',         '$appender' );
    }

    sub test_enabled {
        my ( $test, $report ) = @_;
        my $appender = $test->build_appender;
        is( $appender->enabled,      0, 'Appender not enabled'  );

        my $mt = $test->build_app;
        isa_ok( $mt, 'MT', 'MT' );

        $appender->enabled(1);
        is( $appender->enabled,      1, 'Appender enabled'      );

        $appender->enabled(0);
        is( $appender->enabled,      0, 'Appender not enabled'  );
    }

    sub test_buffer {
        my ( $test, $report ) = @_;
        my $appender = $test->build_appender;
        my @tests = qw( This is a test );
        $appender->buffer( $_ ) for @tests;
        is_deeply( $appender->buffer, [@tests], 'Buffer array works' );
    }

    sub test_flush {
        my ( $test, $report ) = @_;
        my $mt       = $test->build_app;
        my $appender = $test->build_appender;
        my $msg      = 'Testing Testing';
        my $level    = 'ERROR';
        $appender->buffer({ message => $msg, log4p_level => $level, });
        $appender->enabled(1);

        my $log = $test->last_log();
        isa_ok( $log, 'MT::Log', "$log" );
        is( $log->message, $msg );
    }

    sub last_log {
        my $app = MT->instance;
        $app->model('log')->load({}, { limit => 1, direction => 'descend' });
    }

    sub test_log {
        my ( $test, $report ) = @_;
        my $mt = $test->build_app;
        require MT::Logger::Log4perl;
        import MT::Logger::Log4perl qw(get_logger);

        my $error = 'Error test';

        my $l = MT::Logger::Log4perl->get_logger();
        $l->error($error);

        my $log = $test->last_log();
        is( $log->message, $error, 'Error message is last log' );

        $l->debug('Not an error');
        $log = $test->last_log();
        is( $log->message, $error, 'Error message is still last log' );
    }
}
1;

__END__
