package MT::Logger::Log4perl::Config;

use 5.010;
use Moo;

use warnings FATAL => 'all';
use Try::Tiny;
use Log::Log4perl ();
use Path::Tiny;
use Scalar::Util qw( blessed );
use Data::Printer output => 'STDOUT', colored => 0;
use Carp qw( croak );

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


# around BUILDARGS => sub {
#     my $orig = shift;
#     my $class = shift;
#  
#     if ( @_ == 1 && ! ref $_[0] ) {
#         return $class->$orig(ssn => $_[0]);
#     }
#     else {
#         return $class->$orig(@_);
#     }
# };

# sub BUILD {
#     my $self = shift;
#     if ( my $c = $self->has_config ) {
#     }
# }

sub _new {
    my $self = shift;
    return blessed( $self ) ? $self : $self->new(@_);
}

sub init {
    my $self = shift;
    my $conf = $self->config || (@_ ? $self->config(+shift) : undef)
        or croak 'No config defined';
    $self->_initializer($conf)->();
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

#     # TestsFor::MT::Logger::Log4perl::Config->test_config_file()
#         ok 1 - new with args: ( config, /Users/jay/Sites/log4mt.conf )
#         ok 2 - The object isa MT::Logger::Log4perl::Config
#         ok 3 - Obj has_config: 1
# In _initializer with Printing in line 124 of lib/MT/Logger/Log4perl/Config.pm:
# "/Users/jay/Sites/log4mt.conf"
# conf is a path. Sending to MT::Logger::Log4perl
# Printing in line 21 of lib/MT/Logger/Log4perl.pm:
# [
#     [0] "/Users/jay/Sites/log4mt.conf",
#     [1] "HUP"
# ]
# Log::Log4perl configuration looks suspicious: No loggers defined at /Users/jay/perl5/perlbrew/perls/perl-5.10.1/lib/site_perl/5.10.1/Log/Log4perl/Config.pm line 317.
#   Log::Log4perl::Config::_init('Log::Log4perl::Config', '/Users/jay/Sites') called at /Users/jay/perl5/perlbrew/perls/perl-5.10.1/lib/site_perl/5.10.1/Log/Log4perl/Config.pm line 103
#   eval {...} called at /Users/jay/perl5/perlbrew/perls/perl-5.10.1/lib/site_perl/5.10.1/Log/Log4perl/Config.pm line 103
#   Log::Log4perl::Config::init_and_watch('Log::Log4perl::Config', '/Users/jay/Sites/log4mt.conf', 'HUP') called at /Users/jay/perl5/perlbrew/perls/perl-5.10.1/lib/site_perl/5.10.1/Log/Log4perl.pm line 265
#   Log::Log4perl::init_and_watch('Log::Log4perl', '/Users/jay/Sites/log4mt.conf', 'HUP') called at lib/MT/Logger/Log4perl.pm line 21

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


# sub init_config {
#     my $self = shift;
#     my @args = @_;
#     Carp::cluck( ( Log::Log4perl->initialized() ? "Re-i" : "I" )
#                  . "nitializing Log::Log4perl!" );
# 
#     @args or @args = (
#         $self->check_environment,
#         $self->relative_directories,
#         $self->default_config,
#     );
# 
#     my $config = first { $self->_try_config($_) } @args;
#     $config or die "Failed to initialize Log4perl";
# 
#     p $config;
#     return $config;
# }


### _try_config
#
# This method tests a configuration passed as a hash reference with related
# metadata.
#
# MORE TO COME
#
###
# sub _try_config {
#     my ($self, $args ) = @_;
# 
#     $args = $self->_prep_config( $args )
#         or return;
# 
#     return $self->_try_l4p_init( $args );
# }

# sub _prep_config {
#     my ( $self, $args ) = @_;
# 
#     my ($c, $hint, $is_env) = map { $args->{$_} } qw( config type env );
# 
#     # Theoretically, config could be a sub reference
#     $c = $c->() if 'CODE' eq ref($c);
# 
#     # Test config value and short-circuit if we got nothing
#     return unless $c;
# 
#     # If for some strange reason, hint isn't defined, try to detect it
#     $hint //=                                               # Passthru?
#           'HASH'   eq ref($c)                   ? 'hash'    #  OK
#         : 'GLOB'   eq ref($c)                   ? 'fh'      #  OK
#         : 'CODE'   eq ref($c)                   ? 'code'    #  Must eval
#         : 'SCALAR' eq ref($c)                   ? 'string'  #  OK
#         : ( ! ref($c) && $c =~ m/\n/ )          ? 'string'  #  OK
#         : $self->_is_configurator($c)           ? 'object'  #  OK
#         : $self->_is_path($c)                   ? 'path'    #  Must stringify
#                                                 : '';       #  WE'LL SEE...
# 
#     if ( $hint eq 'string' ) {
#         $c = \$c unless ref $c;
#     }
#     elsif ( $hint eq 'path' ) {
#         try {
#             my $p = path($c);
# 
#             # If an ENV is wrong, we warn the user. Otherwise, stay silent
#             # since most values are speculative on our part.
#             if ( $is_env && ! $p->exists ) {
#                 die "$is_env path ($c) could not be found";
#             }
# 
#             # Convert to file if we have a dir. is_dir also checks existence
#             $p = $p->child('log4mt.conf') if $p->is_dir;
# 
#             # Now, check that we have a file.  is_file also checks existence
#             die unless $p->is_file;
# 
#             $args->{path} = $p;
#         }
#         catch {
#             say STDERR $_ if defined($_) and length($_);
#             undef $c;
#         };
#     }
# 
#     return $c ? $args : ();
# }

# sub _try_l4p_init {
#     my ($self, $args) = @_;
# 
#     my $c = $args->{config};
# 
#     try {
#         if ( my $p = $args->{path} ) {
#             # Now send it to init_and_watch.  This will die if not kosher.
#             Log::Log4perl->init_and_watch( $p->stringify, 'HUP' );
#             $c = $p->stringify;
#         }
#         else {
#             Log::Log4perl->init( $c );
#         }
#     }
#     catch {
#         say STDERR $_;
#         undef $c;
#     };
# 
#     return $c;
# }


1;
