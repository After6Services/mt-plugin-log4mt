#!/usr/local/bin/perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Mail;

    use 5.008_008;
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
        my $e = 'jay+send@endevver.com';
        is( $appender->from, $e, "From is $e" );
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
        my $e = 'jay+recip@endevver.com';
        is( $appender->default_recipient, $e,
            "Default recipient is $e" );
    }

    sub test_default_sender  : Tags( appender mtmail ) {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        my $e = 'jay+send@endevver.com';
        is( $appender->default_sender, $e,
            "Default recipient is $e" );
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
