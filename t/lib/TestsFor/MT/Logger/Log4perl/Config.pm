#!/usr/local/bin/perl
{
    package TestsFor::MT::Logger::Log4perl::Config;

    use 5.008_008;
    use MT::Logger::Log4perl;
    use Test::Class::Moose;
        with 'Test::Class::Moose::Role::AutoUse';
    use Test::Fatal;

    sub test_setup {
       my ( $test, $report ) = @_;
       $test->next::method;
       my $driver = $test->class_name->driver_class;
       # say '#'x30, ' Calling '.$test->class_name."->reset in setup ", '#'x30;
       $driver->reset();
       die "Log4perl is still initialized" if $driver->initialized;
       delete $ENV{LOG4MT_CONFIG};
       delete $ENV{MT_HOME};
       undef $Log::Log4perl::Config::WATCHER;
       undef $Log::Log4perl::Config::OLD_CONFIG;
    }

    # sub test_teardown {
    #    my ( $test, $report ) = @_;
    #    $test->next::method;
    #    say 'Calling '.$test->class_name."->reset";
    #    $test->class_name->reset();
    #    delete $ENV{LOG4MT_CONFIG};
    #    delete $ENV{MT_HOME};
    # }

    sub _new {
        my ( $test, $report, $args, $has_exception ) = @_;

        my $cfg = $test->class_name->new(@$args);

        isnt( defined($cfg), undef,
            'new with args: ( '.join(', ', @$args).' )' );
        isa_ok( $cfg, $test->class_name );
        __PACKAGE__->can(@$args ? 'is' : 'isnt')
                   ->( $cfg->has_config, 1, "Obj has_config: ".(@$args?1:0) );

        my $rv;
        if ( $has_exception ) {
            my $exc = exception { $rv = $cfg->init() };
            isnt( $exc, $has_exception, "config->init died" );
        }
        else {
            is(
                exception { $rv = $cfg->init() },
                undef,
                "config->init returned for ".$cfg->config
            );
        }
        $has_exception ? is( $rv, undef, 'Return value: [undef]')
                       : isnt( $rv, undef, "Return value: $rv");
    }

    sub _dir_arg       { [ '/Users/jay/Sites'                    ] }
    sub _good_file_arg { shift->_dir_arg->[0] . '/log4mt.conf' }
    sub _bad_file_arg  { shift->_dir_arg->[0] . '/ksdaksdkashjkhasdkjconf' }
    sub _no_init_error {
        qr/Log::Log4perl configuration looks suspicious: No loggers defined/
    }

    sub test_config  : Tags( config ) {
        shift->_new( @_, [], 1 );
    }

    sub test_config_file  : Tags( config ) {
        my $test = shift;
        $test->_new( @_, [ config => $test->_good_file_arg ] );
    }

    sub test_config_singlearg_file  : Tags( config ) {
        my $test = shift;
        $test->_new( @_, [$test->_good_file_arg] );
    }

    sub test_config_bad_file  : Tags( config ) {
        my $test = shift;
        local $SIG{__WARN__} = sub {};
        $test->_new( @_, [$test->_bad_file_arg], $test->_no_init_error );
    }
}

1;

__END__


# Implicitly means:
#    MT::Logger::Log4perl::Config->new( config => '/path/to/log4mt.conf' );
