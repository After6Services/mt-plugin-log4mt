package MT::Logger::Log4perl::Config;

use Moo;
use 5.010;

use warnings FATAL => 'all';
use Try::Tiny;
use Log::Log4perl ();
use Path::Tiny;
use Scalar::Util qw( blessed );
use Data::Printer output => 'STDOUT', colored => 0;
use Carp qw( croak );
use Carp::Always;

use version 0.77; our $VERSION = qv("v2.0.0");

has 'env_vars' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [qw( LOG4MT_CONFIG  MT_HOME )] },
);

has 'config' => (
    is        => 'ro',
    clearer   => 1,
    predicate => 1,
    # builder   => 1,
);

sub driver_class {
    my $self = shift;
    state $attr = 'MT::Logger::Log4perl';
    $attr = $_[1] // $attr;
}

has driver => (
    is       => 'ro',
    init_arg => 'driver',
    lazy     => 1,
    default  => sub { shift()->driver_class },
    trigger  => sub { shift()->driver_class(+shift) }
);

has autoinit_class => (
    is       => 'ro',
    init_arg => 'autoinit',
    lazy     => 1,
    default  => 'MT::Logger::Log4perl::Config::auto',
);

has default_class => (
    is       => 'ro',
    init_arg => 'default',
    lazy     => 1,
    default  => 'MT::Logger::Log4perl::Config::default',
);

# SingleArgConstructor:
#    MT::Logger::Log4perl::Config->new( '/path/to/log4mt.conf' );
# Implicitly means:
#    MT::Logger::Log4perl::Config->new( config => '/path/to/log4mt.conf' );
sub BUILDARGS {
    my ( $class, @args ) = @_;
    unshift( @args, 'config' ) if @args % 2 == 1;
    return { @args };
};


sub _new {
    my $self = shift;
    return blessed( $self ) ? $self : $self->new(@_);
}

sub init {
    my $self = shift;
    my $conf = $self->config || (@_ ? $self->config(+shift) : undef)
        or croak 'No config defined';
    return $conf if $conf eq '1';          # 1 returned from default.pm
    return $self->_initializer($conf)->(); 
}

sub reset {
    my $self = shift;
    $self    = $self->_new(@_);
    $self->driver_class->reset();
}

sub auto_initialize {
    my $self = shift;
    my %args = @_;
    $self    = $self->_new(%args);
    require Module::Load;
    Module::Load::load( $self->autoinit_class );
    my $config = $self->autoinit_class->new(%args)
        or die "Auto-initialization failed";
}

sub _initializer {
    my $self = shift;
    my $conf = $self->config || $self->config(+shift)
        or croak 'No config defined';
    # warn "_initializer with config: ".$conf;
    my $driver = $self->driver_class;

    if ($driver->initialized) {
        warn "$driver is being re-initialized";
        $driver->reset;
    }

    return sub {
        # say STDERR "In _initializer with ".p($conf);
        if ( $self->_is_path($conf) ) {
            $conf = path($conf);
            try   { MT::Logger::Log4perl::init_and_watch( $conf->stringify, 'HUP' ) }
            catch {  warn $_; undef $conf };


            # say $conf.": conf is a path. Sending to $driver";
            # try   { $driver->init_and_watch( $conf->stringify, $SIG{HUP} ) or Carp::confess('GAH') }
            # catch { warn $_; undef $conf };
        }
        else {
            # say "conf is not a path";
            try   { $driver->init( $conf ) }
            catch { warn $_; undef $conf };
        }
        die "Bad conf" unless $driver->initialized;
        # say STDERR "Finishing _initializer with "
        #          . (defined $conf ? $conf : 'undefined conf');
        return $conf;
    }
}

### _is_configurator
#
#
###
sub _is_configurator {
    my ( $self, $config ) = @_;
    return try { $config->isa('Log::Log4perl::Config::BaseConfigurator') };
}

### _is_path
#
#
###
sub _is_path {
    my ($self, $c) = @_;
    require List::Util;
    return 1
        if try { List::Util::first { $c->isa($_) } qw( Path::Tiny Path::Class) }
        || ( ! ref($c) && try { path($c); 1 } );
    return 0;
}

1;
