package MT::Log::Log4perl::BaseLogger;

use 5.010_001;
use strict;
use warnings;
use Data::Dumper;

use Carp;
use Log::Log4perl;
use MT::Log::Log4perl::Util qw( err emergency_log  );

Log::Log4perl->wrapper_register(__PACKAGE__);

our @levels = qw[ trace debug info warn error fatal ];    

our @methods = qw(error_die   logcroak      get_level     
                  error_warn  logcluck      dec_level
                  logcarp     logconfess    inc_level
                  logdie      add_appender  less_logging
                  logwarn     additivity    more_logging  );

my $methods_installed;

sub new {
    my $pkg   = shift;
    my $args  = shift;
    my $logger_class = __PACKAGE__;     # Default
    
    if (    Log::Log4perl->initialized
        and $pkg ne 'MT::Log::Log4perl::Logger' ) {

        require MT::Log::Log4perl::Logger;
        $logger_class = 'MT::Log::Log4perl::Logger';
    }

    my $self = bless {}, $logger_class;
    $self->init($args);
}


sub init {
    my $self = shift;
    MT::Log::Log4perl::Util::trace();

    unless ( $methods_installed++ ) {
        foreach my $name (@methods, level_variants(@levels)) {
            err("Creating anonymous sub stub for $name");
            no strict 'refs';
            # TODO Check that these work properly
            if ($name =~ /((?<=.)warn)/) {
                *{$name} = sub {  warn @_; };
            }
            elsif ($name =~ /die/) {
                 *{$name} = sub {  die @_; };
            }
            elsif ($name =~ /(confess|cluck|croak|carp)/) {
                 *{$name} = sub {  &{"Carp::".substr($name, 3)}(@_) };
            }
            else {
                *{$name} = sub { };        
            }
        }        
    }

    $self;
}

sub level_variants {
    my @variants;
    foreach my $base (@_) {
        # foreach my $case ($base, uc($base)) {
            foreach my $getset ($base, "is_$base") {            
                push(@variants, $getset)
            }
        # }
    }
    @variants;
}

sub init_logger { trace(); }

sub levels { @levels }

sub methods { @methods }


1;

__END__
