#!/usr/bin/env perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Mail;

    use v5.10.1;
    use Test::Class::Moose;
        with 'Test::Class::Moose::Role::AutoUse';
        extends 'TestsFor::MT::Log::Log4perl::Appender::MT::Base';

    sub test_setup {
        my ( $test, $report ) = @_;
        my $app = $test->build_app;
    }

    sub test_constructor  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->build_appender();
        isa_ok( $appender, 'Log::Log4perl::Appender', '$appender' );
    }

    sub test_app  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        isa_ok( $appender->app, 'MT' );
    }

    sub test_from  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        my $main = $appender->app->config->EmailAddressMain;
        is( $appender->from, $main, "From is EmailAddressMain: $main" );
    }

    sub test_content_type  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        like( $appender->content_type,
              qr/charset/i,
             'Content-type looks good'
        );
    }

    sub test_default_recipient  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        my $main = $appender->app->config->EmailAddressMain;
        is( $appender->from, $main,
            "Default recipient is EmailAddressMain: $main" );
    }

    sub test_log  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $mt = $test->build_app;

        require MT::Mail;
        my $send_called = 0;
        {
            no warnings 'redefine';
            *MT::Mail::send = sub { $send_called = 1 };
        }

        require MT::Logger::Log4perl;
        import MT::Logger::Log4perl qw(get_logger);

        my $error = 'This is an error email';

        my $l = MT::Logger::Log4perl->get_logger('mtmail');
        isa_ok( $l, 'Log::Log4perl::Logger' );
        is( $l->has_appenders, 1, 'Logger has only one appender' );
        isa_ok( Log::Log4perl->appender_by_name('MTMail'),
                'MT::Log::Log4perl::Appender::MT::Buffer', 'mtmail appender' );

        ok( $l->error( subject => 'This is my subject', message => $error ) );
        is( $send_called, 1, 'MT::Mail::send was called' );
    }
}

1;

__END__
