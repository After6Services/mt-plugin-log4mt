package MT::Log::Log4perl;

=head1 NAME

MT::Log::Log4perl - The central engine behind in MT-to-Log4perl interface

=cut

use strict;
use warnings;
use Log::Log4perl 1.39  qw( :nostrict :nowarn
                            :no_extra_logdie_message    );
use Array::Extract      qw( extract );
use Carp                qw( croak   );
use Filter::Simple;
use Sub::Install;

use Data::Printer {     #<---------     FIXME Remove unnecessary dependencies
    caller_info => 1,    #<---------
    colored => 0,
};                      #<---------

use version 0.77; our $VERSION = version->declare('v2.0.0');  # ALPHA - tiny

our ( $VERBOSE, $FILTER_ENABLED, $LOG_CLASS ) = ( 0, 0, 'MT::Log' );

sub VERBOSE { $VERBOSE }

# Execution of this class' import method (via use or explicit call) triggers
# the following
#   * Source filter to resurrect l4p comment lines
#   * Installation of $l4p in caller's package initialized to either
#       - Null logger
#       - Basic Log4perl logger
#   * Legacy imports/exports
#   * Installation of a get_logger function into MT::Log
# See POD documentation for more
sub import {
    my $pkg         = shift;
    my @args        = @_;
    my %wants       = $pkg->_extract_local_import_args( @args );
    my $caller      = caller;

    $FILTER_ENABLED = 1;        # Source filter enabled

    # Create the necessary initial logger and install into $caller
    $pkg->install_minimal_logger({
        category => $caller,
        caller   => $caller,
        null     => ! $wants{l4p},  # Without -all or $l4p, null object
    });

    # Handle legacy exports l4mtdump and VERBOSE
    $pkg->install_l4mtdump( $caller ) if $wants{l4mtdump};
    $VERBOSE = $wants{VERBOSE} ? 1 : 0;

    # Install get_logger() into MT::Log
    __PACKAGE__->init_mt_log();

    # TODO Test that this is needed in this package
    # Log::Log4perl->wrapper_register($pkg);
}

sub new {
    my ($pkg, $args) = @_;
    my $caller = 'HASH' eq ref($args) ? $args->{caller}
                                      : scalar caller();

    unless ( defined( $args ) && 'HASH' eq ref( $args ) ) {
        $args =
        {
            category => ( $args || $caller ),
            caller   => $caller,
        };
    }
    # $args->{l4mtdump} = 1 unless defined $args->{l4mtdump};

    my $self = { %$args };
    bless $self, $pkg;

    return $args->{no_init} ? $self : $self->init($args);
}

sub init_config {
    my $self = shift;
    my $args = shift;

    require MT::Log::Log4perl::Config;
    my $cfg = MT::Log::Log4perl::Config->new();
    $cfg->init( $args );
}

sub logger {
    my $self = shift;
    my $args = shift;
    return unless $self->config;

    require MT::Log::Log4perl::BaseLogger;
    return MT::Log::Log4perl::BaseLogger->new( $args );
}

sub install_minimal_logger {
    my $pkg    = shift;
    my $args   = shift;
    my $logger = $pkg->get_minimal_logger({
        null         => ! $wants{l4p},
        ( map { $_ => $caller } qw(category caller) ),
    });
    $pkg->_install_l4p( $logger, $caller );
}

sub get_minimal_logger {
    my $pkg    = shift;
    my $args   = shift || {};
    my $config = $pkg->init_config({ minimal => 1 });
    Log::Log4perl->get_logger({
        sdsds
        %$args,
    });
};


sub get_logger {
    my $pkg    = shift;
    my $args   = shift || {};
    my $caller = caller;
    # DEBUG my $v = { pkg => $pkg, args => $args, call => $caller }; p $v;
    return $pkg->_null_logger if $args->{null};

    $pkg->init_config();

    my $l4p    = $pkg->new({
        no_init  => 1,
        category => $caller,    # Default
        caller   => $caller,    # Default
        %$args,                 # Overrides the above, if keys specified
    });

    return $l4p->logger();
}

sub init {
    my $self = shift;
    my $args = shift;
    # use Carp; Carp::cluck( "I am in init with args"); p $args;

    require MT::Log::Log4perl::Config;
    if ( MT::Log::Log4perl::Config->new( $args ) ) {
        $Log::Log4perl::Logger::INITIALIZED = 1;
    }

    $args->{initialized} = 1;

    require MT::Log::Log4perl::BaseLogger;
    return MT::Log::Log4perl::BaseLogger->new($args);
}

{
    my $GET_LOGGER_INSTALLED = 0;
    sub init_mt_log {
        return if $GET_LOGGER_INSTALLED;

        require MT;
        eval "require $LOG_CLASS; 1;"
            or die "Could not load $LOG_CLASS: $@";
        return if $LOG_CLASS->can('get_logger');

        require Sub::Install;
        Sub::Install::install_sub({
            code => 'new',
            from => 'MT::Log::Log4perl',
            into => $LOG_CLASS,
            as => 'get_logger',
        });
        $GET_LOGGER_INSTALLED = 1;
    }
}

sub _extract_local_import_args {
    my $pkg = shift;
    my %args;
    %args =    map { $pkg->_expand_arg($_) }
           extract { m/^(-all|\$l4p|VERBOSE|l4mtdump)$/ }
                        @_;
}

sub _expand_arg {
    my $pkg = shift;
    my $arg = shift;
    $arg =~ s/\W//g;
    # Wants -all also mean wants $l4p
    #   but no legacies unless they are also explicitly requested
    ( $arg => 1, ( $arg eq 'all' ? (l4p => 1) : () ));
}

sub _null_logger {
    my $pkg          = shift;
    my $logger_class = shift || 'Class::Null';
    eval "require $logger_class; 1;"
        or die $@;
    $logger_class->new( @_ );
}

# {
#     no strict 'refs';
#     for (qw( VERBOSE FILTER_ENABLED LOG_CLASS )) {
#         warn "Installing function: $_ = $$_";
#         *{"$_"} = sub { eval "\$$_" }
#     }
# }

# Source code filter for automatically resurrecting the ###l4p lines
FILTER_ONLY code => sub {
    if ( $FILTER_ENABLED ) {
        s/^\s*###(l4p->)/\$$1/gsm;
        s/^\s*###l4p//gsm;
        $FILTER_ENABLED = 0;
    }
};


1;

__END__

# {
#     no warnings 'once';
#     *l4mtdump = \&MT::Log::Log4perl::Util::l4mtdump;
# }


# sub _get_logger {
#     shift if ($_[0]||'') eq 'MT::Log' or (ref($_[0])||'') eq 'MT::Log';
#     my $args = shift;
#     my $caller = ((caller)[0]);
#     if ( $caller and ! $caller->can('l4mtdump') ) {
#         require Sub::Install;
#         Sub::Install::install_sub({
#             code => 'l4mtdump',
#             into => $caller,
#         });
#     }
#     my $logger = __PACKAGE__->new(shift || $caller);
# }


=head1 SYNOPSIS

    use MT::Log::Log4perl;

    eval 'defined( $l4p ) && blessed $l4p;';        # True with no errors!
    $l4p->warn("Don't ignore me!");                 # Sorry. No error but noop

    $l4p = MT::Log::Log4perl->new( \%args );
    $l4p->warn("No, I mean it!");                   # Alright then, fine...

    ###l4p $l4p->info( 'Back from the dead!' );     # Auto-resurrection
    
    ###l4p->info("Holy hell, this works too?!");    # SHINY NEW ABBREVIATED
    ###l4p->debug( $obj_or_reference );             # SYNTAXES AND AUTO-DEREF!

OR

    use MT::Log::Log4perl qw( $l4p );
    ###l4p->warn( "This ain't nothing..." );        # You have been warned

OR
    
    use MT::Log::Log4perl -all;
    ###l4p->info( "Same thing" );                   # ...for now.

=head1 "USE"AGE

=over 4

=item use MT::Log::Log4perl ();

This form imports no symbols into the caller's namespace and does not
trigger any C<###l4p> comment line resurrection. It is equivalent to:

    BEGIN { require MT::Log::Log4perl; }

=item use MT::Log::Log4perl;

The normal use syntax has been, let's say, "re-optimized" to eliminate all of
the unnecessary boilerplate associated with the most frequent developer usage
(read: I got tired of typing) illustrated here:

    use MT::Log::Log4perl qw( l4mtdump );
    use Log::Log4perl qw( :resurrect );

    my $l4p = MT::Log::Log4perl->new();

    ###l4p $l4p->fatal('All that work for just one line...');

B<Automatic resurrection>: First, when called this way, C<###l4p> lines are
automatically resurrected eliminating the need to use
L<Log::Log4perl|Log::Log4perl>. To refresh your memmory, that means this:

    ###l4p $l4p->fatal("Heeeeeeere's Johnny!");

is dynamically rendered at compile time as:

    $l4p->fatal("Heeeeeeere's Johnny!");

B<Less typing>: I<In addition to that>, Log4MT adds another resurrection
syntax which cuts out the annoying redundancy:

    ###l4p $l4p->info("This is tired...");
    ###l4p->info("Me likey");

B<Auto-dereferencing>: But wait... There's more! Speaking of annoying
reudundancy, there's no longer any need to get down in the B<dump>s over this
silliness:

    ###l4p $l4p->debug( '$object: ', l4mtdump( $object ));

when you can do B<this!>:

    ###l4p->debug( $object );

See the section below on L<Auto-dereferencing and serialization> for full
details.

B<You get a variable! And you get a variable!>: Indeed, this form triggers
export of the C<$l4p> variable to caller's namespace. However, it is
initialized with NULL object instance (i.e. all calls are no-op) which is
mainly important because it ensures that the new automatic resurrection
feature doesn't blow up your existing code.

    $l4p->info('Hello?');                               # ...
    $l4p->info('Is it me you're looking for?');         # zzzzzzz
    $l4p->how_about_this( 'Wait, let me guess...' );    # ZZZZZZZZZZZZZZZZZZZ

    $l4p = MT::Log::Log4perl->new( \%args );
    $l4p->debug('Now??????');                           # O HAI!!

=item use MT::Log::Log4perl (...)

Same as above except where noted in the section below on L<EXPORTS>.

=back

=head2 EXPORTS

=over 4

=item $l4p

Importing C<$l4p> explicitly in the use line B<skips the NULL object>
instantiation and instead initializes the variable with an B<actual
ready-to-use Log4perl logger instance>, eliminating the need to call
MT::Log::Log4perl->new(). Unless of course you really want to...

=item -all

Imports all available, NON-deprecated exports.  Currently equivalent to:

    use MT::Log::Log4perl qw( $l4p );

=item (DEPRECATED) l4mtdump

Function for deferred serialization and dumping of references (as seen above).
Since this is now the default action, there's no need to use it but it's left
here for backwards compatibility.

=item (DEPRECATED) VERBOSE

Making Log4perl initialization extra noisy.

=back

=head2 Auto-dereferencing and serialization

Log4MT automatically looks for and uses one of the following for
serialization, in order of preference:

=over 4

=item * Data::Printer

=item * Data::Dumper::Names

=item * YAML

=item * Data::Dumper

=back

If either of the first two are installed and used, the debug line above can be
shortened to the following:

    $l4p->debug( $object );

=head1 METHODS

=head2 new

Instantiates an MT::Log::Log4perl object and stores within it the arguments
provided as a hash reference.  Valid arguments include:

=over 4

=item * category

=item * caller

=item * I<others???>

=back

Note that this method NO LONGER initializes and returns a logger object.  If you desire the old functionality, use L<get_logger> instead of L<new>.

=head2 init

=head2 get_logger

This class method (which is also aliased to L<MT::Log::get_logger>) is used to
create a ready-to-use logger object, configured automatically or based on
options provided as arguments to this method.

It is shorthand for the following:

    my $l4p_obj = MT::Log::Log4perl->new();
    $l4p_obj->init_config(\%args);
    return $l4p_obj->logger();

Configuration options can be provided to either C<new()> or C<init_config()>
with no difference in functionality. See L<new> for documentation on
recognized configuration keys.

