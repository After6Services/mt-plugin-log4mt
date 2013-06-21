#!/usr/bin/env perl
{
    package TestsFor::MT::Logger::Log4perl::variant::Easy;

    use MT::Logger::Log4perl qw( :easy );

    use Test::Class::Moose
        extends => 'TestsFor::MT::Logger::Log4perl';

    ###l4p has '+resurrect' => (
    ###l4p     is      => 'ro',
    ###l4p     default => 1,
    ###l4p );

    has '+get_logger_import' => (
        default => 1,
    );
    
    has '+level_import' => (
        default => 1,
    );
    
    has '+easylogger_import' => (
        default => 1,
    );

    has loggerfn => (
        is => 'rw',
        default => sub { +{} },
    );

    sub test_setup {
        my ( $test, $report ) = @_;

        delete $ENV{LOG4MT_CONFIG};
        delete $ENV{MT_HOME};

        $test->loggerfn({
             map { lc($_) => $test->test_class->can($_)   }
            grep { $test->test_class->can($_) }
                @{ $test->imported_easyloggers  }
        });

        $test->test_skip("No imported easy loggers to test")
            unless keys %{ $test->loggerfn };
    }

    sub test_easy_loggers  : Tags( compat importing ) {
        my ( $test, $report ) = @_;

        MT::Logger::Log4perl->reset();

        require Log::Log4perl::Level;
        my $warnish = Log::Log4perl::Level::to_priority('WARN');

        is( MT::Logger::Log4perl->easy_init($warnish), 1,
            "Logging threshold set to WARN" );

        my $levels = $test->loggerfn;

        while ( my ($level, $log) =  each %$levels ) {
            my $rv = $log->("Testing $level easylogger");
            if ( Log::Log4perl::Level::to_priority(uc $level) < $warnish ) {
                is( $rv, undef, uc($level)." message discarded");
            }
            else {
                isnt( $rv, undef, uc($level)." message went through");
            }
        }
    }
}

1;

__END__

