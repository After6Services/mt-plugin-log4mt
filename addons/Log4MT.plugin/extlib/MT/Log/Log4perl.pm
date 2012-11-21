package MT::Log::Log4perl;

use strict;
use warnings;
no warnings 'redefine';
use Log::Log4perl ();
use MT::Log::Log4perl::BaseLogger;
use MT::Log::Log4perl::Util qw( err trace emergency_log );
use Data::Dumper;
use DDP;

use base 'Exporter';
our @EXPORT = qw( l4mtdump );

use version 0.77; our $VERSION = qv('v1.7.6');

our $INITIALIZED    = 0;
our $MT_INITIALIZED = 0;
our $VERBOSE        = 0;

Log::Log4perl->wrapper_register(__PACKAGE__);

sub VERBOSE() {  !! $VERBOSE }

sub new {
    my $pkg    = shift;
    my $args   = shift;
    my $caller = caller;

    unless ( $args && 'HASH' eq ref $args ) {
        $args = {
            category => ( $args || $caller ),
            caller   => $caller,
        };
    }
    $args->{l4mtdump} //= 1;
    
    my $self = bless {}, $pkg;
    return $self->init($args);
}

sub init {
    my $self = shift;
    my $args = shift;
    p $args;

    # Install the l4mtdump helper method into the calling package 
    # unless we were asked specifically not to by the nice user
    $self->install_l4mtdump( $args ) unless ! $args->{l4mtdump};

    $self->init_log4perl( $args )
        unless Log::Log4perl->initialized;

    return MT::Log::Log4perl::BaseLogger->new($args);
}

sub init_log4perl {
    my $self = shift;
    my $args = shift;
    return if Log::Log4perl->initialized;

    require MT::Log::Log4perl::Config;
    MT::Log::Log4perl::Config->new( $args );

    $args->{initialized} = Log::Log4perl->initialized
        or die "Something went wrong! Not sure what..."
}

sub mt_initialized {
    my $pkg = shift;
    $MT_INITIALIZED = @_ ? shift() : $MT_INITIALIZED;
}

sub reinitialize {
    my $pkg = shift;
    my $app = shift;
    $pkg->mt_initialized(1);
    require MT::Log::Log4perl::Appender::MT;
    MT::Log::Log4perl::Appender::MT->enabled(1);
}

sub init_mt_log {
    my $log_class = 'MT::Log';
    eval "require $log_class; 1;";
    $@ and die $@;

    return if $log_class->can('get_logger');

    require Sub::Install;
    Sub::Install::reinstall_sub({
        from => 'MT::Log::Log4perl',
        code => 'new',
        into => $log_class,
        as   => 'get_logger',
    });
}

sub install_l4mtdump {
    my $self     = shift;
    my $args     = shift || { caller => scalar caller };
    my $caller   = $args->{caller};
    my $l4mtdump = MT::Log::Log4perl::Util->can('l4mtdump');

    no strict 'refs';
    *{ref($self).'::l4mtdump'} = $l4mtdump;

    return if $caller->can('l4mtdump');

    require Sub::Install;
    Sub::Install::reinstall_sub({
        code => $l4mtdump,
        into => $caller,
    });
}

1;

__END__

