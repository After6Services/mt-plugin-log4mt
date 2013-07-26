#!/usr/bin/env perl
{
    package TestsFor::MT::Log::Log4perl::Appender::MT::Base;

    use Test::Class::Moose;

    sub test_setup {
       my ( $test, $report ) = @_;
       $test->test_skip("No need to test MT appender test base class");
    }

    sub build_app {
        require MT;
        return MT->instance();
    }

    sub build_appender {
        my $self = shift;
        require Log::Log4perl::Appender;
        Log::Log4perl::Appender->new( $self->class_name, @_ );
    }

    sub last_log {
        my $self = shift;
        my $app  = $self->build_app;
        $app->model('log')->load({}, { limit => 1, direction => 'descend' });
    }

}
1;

__END__
