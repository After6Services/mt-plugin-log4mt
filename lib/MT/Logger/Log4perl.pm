package MT::Logger::Log4perl;

use 5.010001;
use strict;
use warnings FATAL => 'all';
use Import::Into;
use Data::Printer output => 'STDOUT', colored => 1;
use List::Util qw( first );
use List::MoreUtils qw( part );
use Carp::Always;

use version 0.77; our $VERSION = qv("v2.0.0");

use Moo;
extends 'Log::Log4perl';

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

# Because Log4perl is dumb
sub import  {
    my $class    = shift;
    my $importer = caller;

    my @myopts               = qw( l4mtdump );
    my ( $myargs, $l4pargs ) = part { $_ ~~ @myopts ? 0 : 1  } @_;
    # warn "\$myargs: ".p($myargs);

    if ( 'l4mtdump' ~~ @$myargs ) {
        no strict 'refs';
        *{$importer.'::l4mtdump'} = \&l4mtdump;
    }

    # warn "Importing from Log::Log4perl into $importer: ".p($l4pargs);
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
    undef $Log::Log4perl::Config::WATCHER;
    undef $Log::Log4perl::Config::OLD_CONFIG;
};

before get_logger => sub {
    my $self = shift;
    $self->_auto_initialize() unless $self->initialized;
};

sub _auto_initialize {
    my $self   = shift;
    require Module::Load;
    Module::Load::load( $self->config_class_auto );
    my $config = $self->config_class_auto->new()
        or die "Auto-initialization failed";
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


1;

__END__
