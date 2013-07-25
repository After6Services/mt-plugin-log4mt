#!/usr/bin/env perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Mail;

    use 5.010;
    use MT::Logger::Log4perl;
    use Test::Class::Moose;
        with 'Test::Class::Moose::Role::AutoUse';
    use Test::Fatal;
    use Data::Printer output => 'STDOUT', colored => 1;
    use Module::Load;

    sub test_constructor {
        my ( $test, $report ) = @_;
        my %p = ();
        my $appender = $test->build_appender( %p );
        isa_ok( $appender, 'Log::Log4perl::Appender' );
    }

    sub test_app {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        isa_ok( $appender->app, 'MT' );
    }

    sub test_from {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        my $main = $appender->app->config->EmailAddressMain;
        is( $appender->from, $main, "From is EmailAddressMain: $main" );
    }

    sub test_content_type {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        like( $appender->content_type,
              qr/charset/i,
             'Content-type looks good'
        );
    }

    sub test_default_recipient {
        my ( $test, $report ) = @_;
        my $appender = $test->class_name->new();
        my $main = $appender->app->config->EmailAddressMain;
        is( $appender->from, $main,
            "Default recipient is EmailAddressMain: $main" );
    }

    sub test_log {
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
        is( $l->has_appenders, 1 );
        isa_ok( Log::Log4perl->appender_by_name('MTMail'),
            'MT::Log::Log4perl::Appender::MT::Mail' );

        ok( $l->error( subject => 'This is my subject', message => $error ) );
        is( $send_called, 1, 'MT::Mail::send was called' );
    }

    sub build_appender {
        my $self = shift;
        require Log::Log4perl::Appender;
        Log::Log4perl::Appender->new( $self->class_name, @_ );
    }

    sub build_app {
        require MT;
        return MT->instance();
    }

    sub last_log {
        my $app = MT->instance;
        $app->model('log')->load({}, { limit => 1, direction => 'descend' });
    }

}
1;

__END__
