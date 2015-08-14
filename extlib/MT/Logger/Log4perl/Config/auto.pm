package MT::Logger::Log4perl::Config::auto;

use 5.008_008;
use Moo;
    extends 'MT::Logger::Log4perl::Config';
use warnings FATAL => 'all';
use Try::Tiny;
use Carp qw( confess );
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

=head3 Initializing via environment variables

This method is called automatically by the C<get_logger> method if no init
method has been called. It checks two environment variables for values that
indicate the location of the configuration file.

It returns an array of hash references which specify the name
(C<env>) and value (C<config>) of the defined variable as well as the C<type>
of content the parser should expect (C<string>, C<path>, etc) from its value.

=over 4

=item 1. C<LOG4MT_CONFIG> - Path to Log4MT config file

If set, this variable should contain the full, absolute path to your
Log4MT configuration file (which does not have to be named C<log4mt.conf>).
This is useful if, for example, you have many MT installations that use a
single Log4MT configuration file placed in a directory above your
C<DOCUMENT_ROOT>.

=item 2. C<MT_HOME> - Path to MT directory

If set, this variable should contain the full, absolute path to your
MT installation directory. It is normally set automatically by
Movable Type during its initialization but doing so manually (e.g. in
webserver configuration and the login shell init files of any executing
users, e.g. you, the owner of the crontab which runs C<run-periodic-tasks>
and the webserver user) not only speeds up the initialization process but
it also allows you to use Log4MT with a log file in the default location
(C<$MT_HOME/log4mt.conf>) prior to MT's full initialization.

=back

=head3 Searching current working directory and parent directories

Since the executing script or CGI is most likely in either the
MT directory (C<MT_HOME>) directory (alongside the C<log4mt.conf>)
or two levels deep in a plugin's envelope, we test those two directories
relative to the current working directory.

=head3 Minimal default configuration

This method returns a basic configuration which defines appenders for both
standard error (C<Stderr>) and standard output C<Stdout> but defaults to
using only standard error for output.

=head2 default_layouts

=head2 default_filters

=head2 default_appenders

=cut
