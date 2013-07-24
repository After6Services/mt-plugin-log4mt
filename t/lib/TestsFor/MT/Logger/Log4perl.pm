#!/usr/bin/env perl
use lib 't/lib';

{
    package TestsFor::MT::Logger::Log4perl;
    use Test::Class::Moose;
    use Test::Fatal;

    use MT::Logger::Log4perl ();

    has get_logger_import => (
        is      => 'ro',
        default => 0,
    );
    
    has level_import => (
        is      => 'ro',
        default => 0,
    );
    
    has easylogger_import => (
        is      => 'ro',
        default => '',
    );

    has resurrect => (
        is      => 'ro',
        default => 0,
    );

    has imported_levels => (
        is      => 'ro',
        default => sub { [qw( $TRACE $DEBUG $INFO $WARN $ERROR $FATAL)] },
    );

    has imported_easyloggers => (
        is      => 'ro',
        default => sub { [qw( TRACE DEBUG INFO WARN ERROR FATAL )] },
    );

    sub test_startup {
       my ( $test, $report ) = @_;
       $test->next::method;

       delete $ENV{LOG4MT_CONFIG};
       delete $ENV{MT_HOME};
    }

    sub test_new : Tags( compat importing ) {
        my ( $test, $report ) = @_;
        can_ok( 'MT::Logger::Log4perl', 'new');
        like(
            exception { MT::Logger::Log4perl->new() },
            qr/THIS CLASS ISN'T FOR DIRECT USE/,
            "new() fails like Log::Log4perl::new",
        );
    }

    sub test_resurrect_import  : Tags( compat importing resurrect ) {
        my ( $test, $report ) = @_;
        is( $test->resurrect, 0, 'Resurrected: NO' );
    }

    sub test_level_import       : Tags( compat importing levels ) {
        my ( $test, $report ) = @_;
        my $stash = Package::Stash->new($test->test_class);
        is( $stash->has_symbol($_)?1:0, $test->level_import,
            sprintf( "Level %s %s imported to %s",
                    $_, ($test->level_import ? 'is' : 'not'), $test->test_class))
            for @{$test->imported_levels};
    }

    sub test_easylogger_import  : Tags( compat importing ) {
        my ( $test, $report ) = @_;
        is( !! $test->test_class->can($_), $test->easylogger_import,
            sprintf( "Easylogger %s %s imported",
                    $_, ( $test->easylogger_import ? 'is' : 'not'))
          ) for @{$test->imported_easyloggers};
    }

    sub test_get_logger_import  : Tags( compat importing ) {
        my ( $test, $report ) = @_;
        is( $test->test_class->can('get_logger') ? 1 : 0, $test->get_logger_import,
            'get_logger import');
    }

    sub test_get_logger         : Tags( compat logging ) {
        my ( $test, $report ) = @_;
        local $SIG{__WARN__} = sub {};
        my $logger = MT::Logger::Log4perl->get_logger();
        isa_ok( $logger, 'Log::Log4perl::Logger' )
            or explain $logger;
    }

    # sub test_logging            : Tags( compat logging ) {
    #     
    # }

    # local $ENV{LOG4MT_CONFIG} = '/Users/jay/Sites/log4mt.conf';
    # 
    # sub test_logging  : Tags( basic ) {
    #     my ( $test, $report ) = @_;
    # 
    #     $test->class_name->reset();
    # 
    #     {
    #         my $category = 'woot';
    #         my $logger = $test->class_name->get_logger($category);
    #         isa_ok( $logger, 'Log::Log4perl::Logger' );
    # 
    #         my $foo = Test::Log::Log4perl->expect(
    #             [ 'woot', warn => qr/testing warn/ ] );
    #         $logger->warn('testing warn');
    #     }
    # 
    #     {
    #         my $category;
    #         MT::Logger::Log4perl->reset();
    #         my $logger = MT::Logger::Log4perl->get_logger($category);
    #         my $foo = Test::Log::Log4perl->expect(
    #             [ 'TestsFor.MT.Logger.Log4perl', warn => qr/new thing/ ] );
    #         $logger->warn('new thing');
    #     }
    # }
}

1;

__END__

