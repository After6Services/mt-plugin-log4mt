package MT::Logger::Log4perl;

use 5.010001;

use strict;
use warnings FATAL => 'all';
use Carp::Always;
use parent qw( Log::Log4perl );
use Data::Printer output => 'STDOUT', colored => 1;

use Log::Log4perl ();
Log::Log4perl->wrapper_register( __PACKAGE__ );


use version 0.77; our $VERSION = qv("v2.0.0");

sub config_class()          {  'MT::Logger::Log4perl::Config'          }
sub config_class_auto()     {  'MT::Logger::Log4perl::Config::auto'    }
sub config_class_default()  {  'MT::Logger::Log4perl::Config::default' }

# Because Log4perl is dumb
sub init                    {  shift->_init_proxy( 'init',           @_)    }
sub init_once               {  shift->_init_proxy( 'init_once',      @_)    }
sub init_and_watch          {  shift->_init_proxy( 'init_and_watch', @_)    }
sub easy_init               {  shift->_init_proxy( 'easy_init',      @_)    }

sub _init_proxy {
    my $self = shift;
    p(@_);
    my $method = shift;
    # objectify self
    
    # get_logger() can be called in the following ways:
    #
    #   (1) Log::Log4perl::get_logger()     => ()
    #   (2) Log::Log4perl->get_logger()     => ("Log::Log4perl")
    #   (3) Log::Log4perl::get_logger($cat) => ($cat)
    #   
    #   (5) Log::Log4perl->get_logger($cat) => ("Log::Log4perl", $cat)
    #   (6)   L4pSubclass->get_logger($cat) => ("L4pSubclass", $cat)
    #
    # Note that (4) L4pSubclass->get_logger() => ("L4pSubclass")
    # is indistinguishable from (3) and therefore can't be allowed.
    # Wrapper classes always have to specify the category explicitely.
    
    # create config object
    # config sanity check
    # config init
    
    p $Log::Log4perl::Config::WATCHER;
    Log::Log4perl->$method(@_);
}

sub get_logger {
    my $self   = shift;
    my $caller = caller;
    $self->_auto_initialize() unless $self->initialized;
    $self->SUPER::get_logger(@_);
}

sub _auto_initialize {
    my $self   = shift;
    require Module::Load;
    Module::Load::load( $self->config_class_auto );
    my $config = $self->config_class_auto->new()
        or die "Auto-initialization failed";
}

1;

__END__

# sub import {
#     my $class = shift;
#     my $caller = caller;
#     say STDERR "$caller importing from Log4perl: ".(join(', ', @_) || 'NONE');
#     $class->SUPER::import( @_ );
# }

