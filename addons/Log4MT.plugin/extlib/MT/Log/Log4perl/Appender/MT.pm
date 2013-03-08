package MT::Log::Log4perl::Appender::MT;

use 5.010_001;
use strict;
use warnings;
use Log::Log4perl;
use parent  qw( Log::Log4perl::Appender );
use Data::Dumper;

our $ENABLED = 0;
our $BUFFER  = [];

Log::Log4perl->wrapper_register(__PACKAGE__);

####
###  Common %params keys include:   appender  buffer  composite
##                                  composite  filter  layout  level
#                                   log4p_category  min_level  mode  name
sub new {#                          warp_message
    my $proto        = shift;
    my $class        = ref $proto || $proto;
    my %params       = @_;
    my $caller       = (caller(1))[3];

    my $self = {
        name     => "unknown name",
        category => $class,
        caller   => $caller,
        %params,
    };

    bless $self, $class;
    return $self;
}

sub enabled {
    my $self   = shift;
    my $newval = shift;

    return $ENABLED
        unless defined $newval and $newval != $ENABLED;

    $ENABLED = $newval;
    return $ENABLED ? $self->flush() : $ENABLED;
}

###
##  Superclass's arguments:
##      my ($self, $p, $category, $level, $cache) = @_;
#
sub log {
    my $self   = shift;
    my $params = { @_ };
    return $self->flush($params) if $self->enabled;
    return scalar @{ $self->buffer($params) };
}

sub buffer {
    my $self  = shift;
    $BUFFER ||= [];
    push( @$BUFFER, @_ ) if @_;
    $BUFFER;
}

sub flush {
    my $self   = shift;
    my ($data) = @_;
    unless ( $self->enabled ) {
        warn __PACKAGE__.'::flush called before enabled. Buffered data';
        return scalar @{ $self->buffer( $data // () ) };
    }

    my ( $cnt, $mt ) = ( 0, undef );
    my $buffer       = $self->buffer( $data // () );
    while ( @$buffer ) {
        my $d = shift @$buffer or next;
        $mt ||= MT->instance;
        $cnt += $mt->log({
            level   => $self->check_level( $d ),
            message => $self->warp_text( $d ),
        });
    }
    $cnt;
}

sub check_level {
    my $self = shift;
    my $val  = shift;
    unless ( $self->enabled ) {
        warn __PACKAGE__.'::check_level called before enabled.';
        return undef;
    }

    my $log_class = MT->model('log');
    state $level  = { map { $_ => $log_class->$_ }
                        qw( DEBUG INFO WARNING ERROR FATAL SECURITY ) };
    $val    = ref $val eq 'HASH' ? $val->{log4p_level} : 'ERROR';
    $level->{$val || 'ERROR'};
}

sub warp_text {
    my $self     = shift;
    my $params   = shift;
    ref $params or $params = { message => $params, log4p_level => 'INFO' };
    unless (     ref $params eq 'HASH'
             and $params->{message}
             and $params->{log4p_level} ) {
        die "Unexpected data in warp_text: \$params = ".Dumper($params);
    }

    my $msg = $params->{message};
    $msg = join( ' ', @$msg ) if 'ARRAY' eq ref $msg;
    return $msg;
}

sub MT::Log::FATAL ()  { 256 }

__END__


########################################################################

package MT::Log;

sub INFO ()     {1}
sub WARNING ()  {2}
sub ERROR ()    {4}
sub SECURITY () {8}
sub DEBUG ()    {16}

sub FATAL ()    {256}

$INC{'MT::Log'} = __FILE__;

1;


########################################################################

package MT;
use Data::Printer {
    return_value => 'pass',
};

sub instance { __PACKAGE__ }

sub model {
    # warn "In ".__PACKAGE__."::model\n";
    return 'MT::Log'
}

sub log {
    my $pkg = shift;
    warn "In ".__PACKAGE__."::log\n";
    p @_;
    return scalar @_;
}

$INC{'MT'} = __FILE__;

########################################################################

package main;

use Test::More;
use Test::Warn;

is( MT->instance, 'MT', 'MT->instance returns package name');
my $app = new_ok( 'MT::Log::Log4perl::Appender::MT' );
is( $app->enabled,          0, 'Not enabled' );
is_deeply( $app->buffer,   [], '$app->buffer is empty array ref'   );

is_deeply( $app->buffer('Test 1'), ['Test 1'], 'First buffered message' );
is_deeply( $app->buffer('Test 2'), ['Test 1','Test 2'], 'Second buffered message' );
is_deeply( $app->buffer('Test 3'), ['Test 1','Test 2','Test 3'], 'Third buffered message' );
is_deeply( $app->buffer,   ['Test 1','Test 2','Test 3'], '$app->buffer has three elements'   );

my $cnt;
warning_like(
    sub {
        is(
            $cnt = $app->flush(), 3, 'Flushed!'
        )
    },
    qr/called before enabled/,
    '"Not enabled" warning from flush()'
);
is_deeply( $app->buffer, ['Test 1','Test 2','Test 3'], '$app->buffer is still full' );

warning_like(
    sub {
        is(
            $app->check_level('FATAL'), undef, 'Check level FATAL = undef'
        )
    },
    qr/called before enabled/,
    '"Not enabled" warning from check_level()'
);


is( $app->enabled(1), 3, 'Enabled returned number of flushed items' );
is_deeply( $app->buffer, [], '$app->buffer is now empty' );

use Log::Log4perl qw( get_logger );
Log::Log4perl->init(config());
my $logger = get_logger();

$logger->fatal('HEY YOU');
$logger->fatal('No really, hey you!', 'Here are two');

done_testing();

sub config {
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

__END__
