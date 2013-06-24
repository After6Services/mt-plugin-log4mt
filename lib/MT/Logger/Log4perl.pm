package MT::Logger::Log4perl;

use 5.010001;
use strict;
use warnings FATAL => 'all';
use Import::Into;
use Data::Printer output => 'STDOUT', colored => 1;
# use Carp::Always;

use version 0.77; our $VERSION = qv("v2.0.0");

use Moo;
extends 'Log::Log4perl';

Log::Log4perl->wrapper_register( __PACKAGE__ );

sub config_class()          {  'MT::Logger::Log4perl::Config'          }
sub config_class_auto()     {  'MT::Logger::Log4perl::Config::auto'    }
sub config_class_default()  {  'MT::Logger::Log4perl::Config::default' }

# Because Log4perl is dumb
sub import  { shift; Log::Log4perl->import::into ( scalar caller, @_ ) }

around [qw( init init_once init_and_watch easy_init appender_by_name
            appender_thresholds_adjust eradicate_appender )] => sub {
    my $orig = shift;
    my $self = shift;
    my @args = @_;
    $args[0] = 'Log::Log4perl' if  $args[0] eq __PACKAGE__;
    # p @args;
    $orig->($self, @args);
};

after reset => sub {
    undef $Log::Log4perl::Config::WATCHER;
    undef $Log::Log4perl::Config::OLD_CONFIG;
};

before get_logger => sub {
    my $self = shift;
    $self->_auto_initialize() unless $self->initialized;
};

sub _auto_initialize {
    my $self   = shift;
    require Module::Load;
    Module::Load::load( $self->config_class_auto );
    my $config = $self->config_class_auto->new()
        or die "Auto-initialization failed";
}

1;

__END__
