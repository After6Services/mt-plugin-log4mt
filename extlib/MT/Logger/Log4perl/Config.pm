package MT::Logger::Log4perl::Config;

use Moo;
use 5.008_008;
use warnings FATAL => 'all';
use Try::Tiny;
use Log::Log4perl ();
use Path::Tiny;
use Scalar::Util qw( blessed );
use Carp qw( croak );
use Carp::Always;

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

has 'env_vars' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [qw( LOG4MT_CONFIG  MT_HOME )] },
);

has 'config' => (
    is        => 'rwp',
    clearer   => 1,
    predicate => 1,
    # builder   => 1,
);

sub driver_class {
    my $self = shift;
    $self->{__driver_class} = $_[1]
                           // $self->{__driver_class}
                           // 'MT::Logger::Log4perl';
}

has 'driver' => (
    is       => 'ro',
    init_arg => 'driver',
    lazy     => 1,
    default  => sub { shift()->driver_class },
    trigger  => sub { shift()->driver_class(+shift) }
);

has 'autoinit_class' => (
    is       => 'ro',
    init_arg => 'autoinit',
    lazy     => 1,
    default  => 'MT::Logger::Log4perl::Config::auto',
);

has 'default_class' => (
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
    my $conf = $self->has_config ? $self->config : $self->_set_config(+shift)
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

__END__

=head1 NAME

MT::Logger::Log4perl::Config - Configuration class for Log4MT

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    my $cfg = MT::Logger::Log4perl::Config->new();
    $cfg->init_config() or die "Could not initialize Log4MT";
    $cfg;

    use MT::Logger::Log4perl::Config;

    my $foo = MT::Logger::Log4perl::Config->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 auto_initialize

=head2 init_config

This method is called once by the builder method for MT::Logger::Log4perl's
C<config> attribute.  By default, when called with no arguments, it defines
a series of fallback configuration options and evaluates each until the first
one succeeds or all options are exhausted (and dies).

=over 4

=item 1. Environment variables

=item 2. Relative directories

=item 3. Default config

=back

Each is described by the appropriately named methods detailed in subsequent
sections.

If, however, arguments are passed, they are evaluated instead of the built
in options. Arguments should be hash references defining the following keys:

=over 4

=item * C<config> (required)

Some value that Log4perl can use to configure itself.  This could be a
filesystem path, a scalar or hash reference, a file handle or even an object
whose class inherits from L<Log::Log4perl::Config::BaseConfigurator>.  See
L<Log::Log4perl> for more details on valid arguments for its C<init> and
C<init_and_watch> methods.

=item * C<type> (recommended)

This specifies the type C<config> value provided which serves as a hint for
how to handle it.  This is really only essential when passing a plain string
because it could be a C<path> or a simple C<string> containing configuration
text.  However, specifying the C<type> obviates the need to perform those
checks and hence speeds up evaluation.

Valid values are currently: C<string, path, hash, fh, code, object>

=item * C<env> (optional)

If the C<config> value is coming from an environment variable, specifying the
variable name as a value for C<env> will supply a warning in the case where
the config fails.

    { config => $ENV{MY_L4MT_CONF}, type => 'path', env => 'MY_L4MT_CONF' }

=back

=head1 AUTHOR

Jay Allen, Endevver LLC, C<< <jayallen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mt-log4perl at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MT-Log4perl>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MT::Log4MT


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MT-Log4perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MT-Log4perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MT-Log4perl>

=item * Search CPAN

L<http://search.cpan.org/dist/MT-Log4perl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jay Allen, Endevver LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
