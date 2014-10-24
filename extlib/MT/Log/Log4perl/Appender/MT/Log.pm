package MT::Log::Log4perl::Appender::MT::Log;

use Moo;
use 5.008_008;
use Try::Tiny;

use Log::Log4perl;
Log::Log4perl->wrapper_register(__PACKAGE__);

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

sub MT::Log::FATAL ()  { 256 }

sub log {
    my  ( $self, %params )  = @_;
    my $log       = { $self->_extract_parameters( $params{message} ) };
    $log->{level} = $self->_check_level( $params{log4p_level} ),
    MT->instance->log($log);
}

sub _check_level {
    my ( $self, $text ) = @_;
    my $log_class = MT->model('log');
    my $level     = { map { $_ => $log_class->$_ }
                         qw( DEBUG INFO WARNING ERROR FATAL SECURITY ) };
    $level->{$text || 'INFO'};
}

sub _extract_parameters {
    my ( $self, $param ) = @_;
    my $msg = join( ' ', @$param );
    unless ( $msg =~ m{called at .*? line} ) {
        $msg .= ' '.Carp::longmess();
    }
    return ( message => $msg );
}

1;

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
use Log::Log4perl qw( get_logger :levels );

Log::Log4perl->init(config());

my $app = MT->instance;
isa_ok( $app, , 'MT', 'MT->instance' );

my $logger = get_logger();
isa_ok( $logger, 'Log::Log4perl::Logger', '$logger' );

$logger->debug('debug should be '.MT::Log::DEBUG );
$logger->info('info should be '.MT::Log::INFO );
$logger->warn('warning should be '.MT::Log::WARNING );
$logger->error('error should be '.MT::Log::ERROR );
$logger->fatal('fatal should be '.MT::Log::FATAL );

done_testing();

sub config {
\q(
    log4perl.logger         = TRACE, Errorlog, MTLog
    layout_class            = Log::Log4perl::Layout::PatternLayout::Multiline
    layout_stderr           = %p> %m (in %M() %F, line %L)%n
    layout_pattern_dated    = %d %p> %c %M{1} (%L) | %m%n
    layout_pattern_minimal  = %m%n
    layout_pattern_trace    = %d %p> #########################   "%c %M{1} (%L)"   #########################%n%d %p> %m  [[ Caller: %l ]]%n
    log4perl.appender.MTLog               = MT::Log::Log4perl::Appender::MT::Log
    log4perl.appender.MTLog.warp_message  = 0
    log4perl.appender.MTLog.layout        = Log::Log4perl::Layout::NoopLayout
    log4perl.appender.MTLog.Threshold               = ERROR
    log4perl.appender.Errorlog                          = Log::Log4perl::Appender::Screen
    log4perl.appender.Errorlog.stderr                   = 1,
    log4perl.appender.Errorlog.layout                   = ${layout_class}
    log4perl.appender.Errorlog.layout.ConversionPattern = ${layout_stderr}
    log4perl.appender.Errorlog.Threshold                = WARN
);
}

__END__

log4perl.appender.MTLogUnbuffered               = MT::Log::Log4perl::Appender::MT::Log
log4perl.appender.MTLogUnbuffered.warp_message  = 0
log4perl.appender.MTLogUnbuffered.layout        = Log::Log4perl::Layout::NoopLayout
log4perl.appender.MTLog                         = MT::Log::Log4perl::Appender::MT::Buffer
log4perl.appender.MTLog.Threshold               = ERROR
log4perl.appender.MTLog.appender                = MTLogUnbuffered


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
            $app->_check_level('FATAL'), undef, 'Check level FATAL = undef'
        )
    },
    qr/called before enabled/,
    '"Not enabled" warning from _check_level()'
);


is( $app->enabled(1), 3, 'Enabled returned number of flushed items' );
is_deeply( $app->buffer, [], '$app->buffer is now empty' );

