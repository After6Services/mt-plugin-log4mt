package MT::Log::Log4perl;

use parent qw( MT::Logger::Log4perl );

use Log::Log4perl;
Log::Log4perl->wrapper_register( __PACKAGE__ );

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

sub new { MT::Logger::Log4perl->get_logger() }

sub trace {
    my ($self, @args) = @_;
    @args = ('') unless scalar @args;
    $self->SUPER::trace( @args );
}

1;
