package MT::Log::Log4perl;

use parent qw( MT::Logger::Log4perl );

require Log::Log4perl;
Log::Log4perl->wrapper_register( __PACKAGE__ );

sub new { MT::Logger::Log4perl->get_logger() }

sub trace {
    my ($self, @args) = @_;
    @args = ('') unless scalar @args;
    $self->SUPER::trace( @args );
}

1;
