package MT::Log::Log4perl::Logger;

use 5.010_001;
use strict;
use warnings;
use Data::Dumper;

use parent qw(MT::Log::Log4perl::BaseLogger);

use Log::Log4perl qw(:levels :resurrect );
use MT::Log::Log4perl::Util qw( err emergency_log trace );

Log::Log4perl->wrapper_register(__PACKAGE__);
# Log::Log4perl->wrapper_register( 'Carp' );

use vars qw($trace_wrapper $logger_methods_installed);

sub init {
    my $self = shift;
    my $args = shift;
    trace();
    $self->SUPER::init(@_);
    $self->init_logger($args->{category});
}

sub init_logger {
    my $self = shift;
    my $cat = shift;
    trace();
    err(sprintf "init_logger being called from %s "
        ."with category %s\n", (caller(1))[3], ($cat||'NULL'));

    $self->{logger} = eval {

        local $Log::Log4perl::caller_depth =
              $Log::Log4perl::caller_depth + 2;
         Log::Log4perl::get_logger($cat);
    };

    if ($@) { die "Could not get logger from Log::Log4perl: $@";
    }  else { init_handlers();
    }

    $self->{logger};
}

sub init_handlers {
    return if $logger_methods_installed;
    trace();

    no warnings qw(redefine);
    require Log::Log4perl::Logger;
    $trace_wrapper = \&Log::Log4perl::Logger::trace;
    *Log::Log4perl::Logger::trace = 
        sub {
            my $self = shift;
            my @messages = @_;
            $messages[0] = ' ' if !defined $messages[0] or $messages[0] eq '';
            # $Log::Log4perl::caller_depth += 1;
            $trace_wrapper->($self, @messages);
            # $Log::Log4perl::caller_depth -= 1;
        };
    
    # Install WARN and DIE signal handlers
    my $prevwarn = ref($SIG{__WARN__}) ? $SIG{__WARN__} : sub { };
    $SIG{__WARN__} = sub {
        local $Log::Log4perl::caller_depth
            = $Log::Log4perl::caller_depth + 1;
        # $prevwarn->(@_);
        my $l = Log::Log4perl->get_logger('');
        $l->warn(@_);
    };

    $logger_methods_installed++;
}

1;
__END__

