package MT::Log::Log4perl::Appender::MT::Buffer;

use strict;
use warnings;
use 5.008_008;
use parent qw( Log::Log4perl::Appender::Buffer );
use Try::Tiny;

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

sub new {
    my ($proto, %options) = @_;
    my $class             = ref $proto || $proto;
    my $self              = $class->SUPER::new(%options);

    # We are a composite appender
    $self->composite(1);
    # Wrap SUPER class' trigger to combine with is_mt_initialized
    my $super_trigger = $self->{trigger};
    $self->{trigger} = sub {
        my $self = shift;
        if ( ref $super_trigger eq 'CODE' ) {
            return 0 unless $super_trigger->($self, @_);
        }
        return $self->is_mt_initialized;
    };

    return $self;
}

sub is_mt_initialized {
    my $self = shift;
    state $initialized = 0;
    unless ( $initialized ) {
        my $app      = try { no warnings 'once'; $MT::mt_inst };
        if ( ref($app) && $app->isa('MT') ) {
            $initialized = 1;
        }
    }
    return $initialized;
}

1;