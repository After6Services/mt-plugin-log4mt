package MT::Logger::Log4perl::Config::auto;

use 5.010;
use Moo;
    extends 'MT::Logger::Log4perl::Config';
use warnings FATAL => 'all';
use Try::Tiny;
use Carp qw( confess );
use Data::Printer output => 'STDOUT', colored => 0;
use List::Util qw( first );
use Scalar::Util qw( blessed );
use Path::Tiny;
use Carp::Always;

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

has '+config' => (
    lazy      => 1,
    builder   => 1,
);

sub _build_config {
    my $self   = shift;
    my $config = first { $self->_initializer($_)->() }
                       ( $self->_config_env_vars, $self->_config_search );

    unless ( $config ) {
        warn "Falling back to default configuration in ".$self->default_class;
        require Module::Load;
        Module::Load::load( $self->default_class );
        $config = $self->default_class->new()->init()
            or die "Failed to initialize Log4perl";
    }

    p $config;
    return $config;
}

sub _config_env_vars {
    my $self = shift;
    my @paths;
    foreach my $var ( @{ $self->env_vars } ) {
        next unless $ENV{$var};
        try   {
            my $p = path( $ENV{$var} );
            $p->is_dir  and $p = $p->child('log4mt.conf');
            $p->is_file and push( @paths, $p );
        }
        catch {
            warn
              "Bad $var environment variable setting: $ENV{$var}";
        };
    }
    return @paths;
}


sub _config_search {
    my $self   = shift;
    my $curdir = Path::Tiny->cwd;
    my @paths;
    do {{
        my $conf = $curdir->child('log4mt.conf');
        $conf->is_file && push( @paths, $conf );
        $curdir = $curdir->parent;
     }} until $curdir->stringify eq Path::Tiny->rootdir;
    return @paths;
}

1;

__END__
