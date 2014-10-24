package MT::Logger::Log4perl;

use Moo;
    extends 'Log::Log4perl';

use 5.008_008;
use warnings FATAL => 'all';
use Import::Into;
use List::Util qw( first );
use List::MoreUtils qw( part );

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

use Carp::Always;
use Data::Printer output => 'STDOUT', colored => 1;

Log::Log4perl->wrapper_register( __PACKAGE__ );

our $L4MTDUMP_FILTER_OPTIONS = [
    # MODULE ################# FUNCTION #
    { 'DDP'                 => 'p'      },
    { 'Data::Dumper::Names' => 'Dumper' },
    { 'Data::Dumper'        => 'Dumper' },
];

sub config_class()          {  'MT::Logger::Log4perl::Config'          }
sub config_class_auto()     {  'MT::Logger::Log4perl::Config::auto'    }
sub config_class_default()  {  'MT::Logger::Log4perl::Config::default' }

sub import  {
    my $class    = shift;
    my $importer = caller;
    my @myopts   = qw( l4mtdump get_logger );
    my ( $myargs, $l4pargs ) = part { $_ ~~ @myopts ? 0 : 1  } @_;

    if ( 'l4mtdump' ~~ @$myargs ) {
        no strict 'refs';
        *{$importer.'::l4mtdump'} = \&l4mtdump;
    }

    if ( 'get_logger' ~~ @$myargs ) {
        no strict 'refs';
        *{$importer.'::get_logger'} = sub { $class->get_logger(@_) };
    }

    Log::Log4perl->import::into ( $importer, @$l4pargs );
}

around [qw( init init_once init_and_watch easy_init appender_by_name
            appender_thresholds_adjust eradicate_appender )] => sub {
    my $orig = shift;
    my $self = shift;
    my @args = @_;
    $args[0] = 'Log::Log4perl' if  $args[0] eq __PACKAGE__;
    # p @args;
    $orig->($self, @args);
};

after reset => sub {
    no warnings 'once';
    undef $Log::Log4perl::Config::WATCHER;
    undef $Log::Log4perl::Config::OLD_CONFIG;
};

sub get_logger {
    my $self = shift;
    $self->_auto_initialize() unless Log::Log4perl->initialized;
    Log::Log4perl->get_logger(@_);
}

sub reinitialize {
    my $self     = shift;
    my $cfg_file = shift;
    $self->initialized
        and (warn "Resetting for reinitialize"), $self->reset;
    require Module::Load;
    Module::Load::load( $self->config_class );
    my $config = $self->config_class->new( config => $cfg_file );
    $config->init()
        or die "Re-initialization failed";
    return 1;
}

sub _auto_initialize {
    my $self   = shift;
    require Module::Load;
    Module::Load::load( $self->config_class_auto );
    my $config = $self->config_class_auto->new();
    $config->init()
        or die "Auto-initialization failed";
    return $config;
}

sub get_l4mtdump_filter {
    state $_l4mtdump_filter = do {
        my ( $mod, $func ) =   map { %$_ }
                             first { my ($m) = %$_;
                                     eval "require $m; 1;" ? 1 : 0;
                                   } @$L4MTDUMP_FILTER_OPTIONS;
        sub {
            my $ref = shift;
            $mod->import( return_value => 'dump', caller_info => 0 )
                if $mod eq 'DDP';
            return $mod->can($func)->($ref);
        };
    };
}

sub l4mtdump {
    return unless @_;
    return shift() if @_ == 1 and not ref $_[0];    # Non-ref scalar
    my $ref = @_ > 1 ? [ map { \$_ } @_ ]           # Hash or array
                     : shift;                       # Single reference
    return { value  => $ref, filter => get_l4mtdump_filter(), };
}



################
package MT::Log;
################

Log::Log4perl->wrapper_register(__PACKAGE__);

sub get_logger;

*get_logger = sub {
    shift if $_[0] and $_[0] eq __PACKAGE__;
    # FIXME Broke backcompat with MT::Log->get_logger(). subroutine name is incorrect below
    #    2013/08/03 00:38:15 DEBUG> GneGetFeedback main:: (50) | GneGetFeedback
    # Log::Log4perl::get_logger( @args );
    MT::Logger::Log4perl->get_logger( @_ || scalar caller );
};
1;

__END__

=head1 NAME

MT::Logger::Log4perl - Configuration class for Log4MT

=head1 VERSION

Version 2.0.0

=head1 SYNOPSIS

    use MT::Logger::Log4perl qw( get_logger :resurrect );
    ###l4p my $log = get_logger();    # Auto-configuration!
    ###l4p $log->info("All Log4perl imports work!");

=head1 DESCRIPTION

Yada...

=head1 RATIONALE

Log4perl views a lack of initialization as a programmer error and plays it
B<SUPER> conservative, refusing to output anything except a warning:

    Log4perl: Seems like no initialization happened. Forgot to call init()?

That may make sense in a lot of environments, but not with Movable Type for
a number of reasons:

=over 4

=item 1. Reliable initialization requires hacking C<< MT::init >>

There are many entrance points (e.g. CGI scripts, command-line execution,
cron-driven periodic tasks, etc) into the MT code base so the only
foolproof way to initialize Log4perl for use throughout is by adding it to
the core initialization methods in C<MT.pm>. This is obviously a non-starter
for any 3rd-party developer.

=item 2. Distributed initialization is stupid and leads to conflicts

Log4perl is a singleton (*sigh*) and I<really> doesn't like to be
initialized more than once so it's not advisable for each plugin developer
to blindly initialize Log4perl in each and every module of every plugin.
Log4perl offers the C<init_once> method as a solution to the problem but
that also means that only one developer's configuration would win:

    use Log::Log4perl qw( get_logger );
    Log::Log4perl->init_once( CONFIG );  # Nyahhh nyahhh!

Then there's the issue of what to actually put in C<CONFIG>.  If MT isn't
initialized, you don't yet have C<$ENV{MT_HOME}> and you don't even know
whether the admin has put the default C<log4mt.conf> there in the first
place.  Of course, you could check to see which would have to look something
like this B<in every single module you want to use Log4perl in>:

    use Log::Log4perl qw( get_logger );
    unless ( Log::Log4perl->initialized ) {
        # Oh, this would be SO much easier if we could assume some CPAN
        # dependencies but since MT rolls-its-own in order to reduce
        # dependencies, 3rd-party developers have to as well unless they're
        # really critical...  SOFA KING ANNOYING!
        my @dirs = ( defined($ENV{MT_HOME}) ? $ENV{MT_HOME} : () );
        my $dir = File::Spec->curdir;
        do {
            push( @dirs, $dir )
            $dir = dirname($dir);
        } while ( $dir ne '/' );

        my $path;
        use Try::Tiny;   # I can't--no, I won't do without it...
        foreach my $base ( @dirs ) {
            $path = File::Spec->catfile( $base, 'log4mt.conf' );
            try   { Log::Log4perl->init_and_watch( $path, 'HUP' ) }
            catch { undef $path };
            last if $path;
        }
    }

    # And now...
    my $logger = get_logger();

To slim that down, you could just put in some derived, relative path to your
own config file (once you figure out where it is relative to the executing
process) or even a config string reference (holy cow, that's a lot of
typing). But B<should> a single 3rd-party plugin developer be dictating
where every admins' logging should go?  Not if they want their plugins to be
used by anyone...

So, basically, you'd be left with only one option:

    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($DEBUG) unless Log::Log4perl->initialized;

    DEBUG "This level of control sucks...";

=item 3. We know that logging to C<STDERR> is almost always okay.

...as a last resort and far better than silently discarding log messages.
What's more, if it's I<not> okay, there's a very simple fix for the admin:
Put the bundled C<log4mt.conf> file in the right place!

=back

MT::Logger::Log4perl encapsulates all of the above madness and does it in a
way that yields, at worst, basic logging to STDERR.


=head1 EXPORT

Same as L<Log::Log4perl>.

=head1 METHODS

MT::Logger::Log4perl is a subclass of L<Log::Log4perl> and hence supports all
of the same methods, functions and options as its parent.  Below, we will
describe the changes made to L<Log::Log4perl|Log::Log4perl's> methods to
take advantage of MT's default setup.

=head2 get_logger( [CATEGORY] )

Like C<Log::Log4perl::get_logger>, this method returns a logger for an
optionally specified C<CATEGORY> and in fact, if you have already called
L<init>, L<init_once> or L<init_and_watch> before calling this method, it is
completely synonymous with it.

    use MT::Logger::Log4perl qw( get_logger );
    MT::Logger::Log4perl->init( CONFIG );       # See Log::Log4perl::init()
    my $logger = get_logger();

    # The above is exactly the same as:
    #   use Log::Log4perl qw( get_logger );
    #   Log::Log4perl->init( CONFIG );
    #   my $logger = get_logger();

Where this method differs is that when it is called without first calling
one of the initialization methods, it attempts to automatically initialize
itself.

    use MT::Logger::Log4perl qw( get_logger );
    my $logger = get_logger();      # Auto-initialization!
    $logger->warn('Yeeeeeah!');

See L<RATIONALE> for details.

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
