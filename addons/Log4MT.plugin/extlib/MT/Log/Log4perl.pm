package MT::Log::Log4perl;

use 5.010_001;
use strict;
use warnings;
no warnings 'redefine';
use Log::Log4perl ();
use MT::Log::Log4perl::BaseLogger;
use List::Util qw( first );
use base 'Exporter';
our @EXPORT = qw( l4mtdump );

use version 0.77; our $VERSION = qv('v1.7.6');

Log::Log4perl->wrapper_register(__PACKAGE__);

our $INITIALIZED     = 0;
our $MT_INITIALIZED  = 0;
our $VERBOSE         = 0;
our $L4MTDUMP_FILTER_OPTIONS = [
    # MODULE ################# FUNCTION #
    { 'DDP'                 => 'p'      },
    { 'Data::Dumper::Names' => 'Dumper' },
    { 'Data::Dumper'        => 'Dumper' },
];


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
    my $self = bless {}, $pkg;
    return $self->init($args);
}

sub init {
    my $self = shift;
    my $args = shift;
    # p $args;
    unless ( Log::Log4perl->initialized ) {
        $self->init_log4perl;
        $self->init_mt_log();
    }
    return MT::Log::Log4perl::BaseLogger->new($args);
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

sub init_log4perl {
    my $self = shift;
    for ( $self->default_config, $self->basic_config ) {
        return $self if $self->try_config( $_ );
    }
    die "Failed to initialize Log4perl";
}

sub init_mt_log {
    my $self      = shift;
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

sub try_config {
    my $self   = shift;
    my $config = shift;
    local $@ = undef;
    eval {
        Log::Log4perl->init( $config )
            or die "Configuration rejected by Log::Log4perl";
        1;
    };
    if ($@) {
        warn $@;
        return 0;
    }
    1;
}

sub default_config {
    File::Spec->catfile( ($ENV{MT_HOME} || '.'), 'log4mt.conf' );
}

sub basic_config {
    my $config = q(
log4perl.logger         = TRACE, Errorlog, MTLog
layout_class            = Log::Log4perl::Layout::PatternLayout::Multiline
layout_stderr           = %p> %m (in %M() %F, line %L)%n
layout_pattern_dated    = %d %p> %c %M{1} (%L) | %m%n
layout_pattern_minimal  = %m%n
layout_pattern_trace    = %d %p> #########################   "%c %M{1} (%L)"   #########################%n%d %p> %m  [[ Caller: %l ]]%n
log4perl.appender.MTLog                             = MT::Log::Log4perl::Appender::MT
log4perl.appender.MTLog.warp_message                = 0
log4perl.appender.MTLog.layout                      = Log::Log4perl::Layout::NoopLayout
log4perl.appender.MTLog.Threshold                   = ERROR
log4perl.appender.Errorlog                          = Log::Log4perl::Appender::Screen
log4perl.appender.Errorlog.stderr                   = 1,
log4perl.appender.Errorlog.layout                   = ${layout_class}
log4perl.appender.Errorlog.layout.ConversionPattern = ${layout_stderr}
log4perl.appender.Errorlog.Threshold                = WARN
);
    return \$config;
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
    return unless @_;                               # No args
    return shift() if @_ == 1 and not ref $_[0];    # Non-ref scalar
    my $ref = @_ > 1 ? [ map { \$_ } @_ ]           # Hash or array
                     : shift;                       # Single reference
    return { value  => $ref, filter => get_l4mtdump_filter(), };
}

1;

__END__

# package main;
#
# use Test::More;
# use DDP;
# MT::Log::Log4perl->import();
# my $l4p = MT::Log::Log4perl->new()
#     or die "Shit";
# isa_ok( $l4p, 'Log::Log4perl::Logger', 'Logger' );
# p $l4p;
# explain $l4p;
#
# $l4p->warn('Testing', l4mtdump($l4p));
# done_testing();
#
#
#
# __END__
