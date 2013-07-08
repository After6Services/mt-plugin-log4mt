package MT::Logger::Log4perl::Config::default;

use 5.010;
use Moo;
    extends 'MT::Logger::Log4perl::Config';

use warnings        FATAL => 'all';
use Try::Tiny;
use Carp            qw( confess );
use Data::Printer   output => 'STDOUT', colored => 0;
use List::Util      qw( first );
use Scalar::Util    qw( blessed );
use Path::Tiny;
use Carp::Always;

has '+config' => (
    # lazy      => 1,
    builder   => 1,
);

sub _build_config {
    my $self   = shift;
    my $level     = $self->default_level;

    my $l = Log::Log4perl->get_logger();
    $l->level( $level );
    $l->add_appender($_) for values %{ $self->default_appenders() };

    return 1;
}

sub default_level {
    my $self = shift;
    require Log::Log4perl::Level;
    state $level = Log::Log4perl::Level::to_priority('TRACE');
    return $level;
}

sub default_layouts {
    require Log::Log4perl::Layout;
    state $mark          = '#########################';
    state $multiline_pat = 'Log::Log4perl::Layout::PatternLayout::Multiline';
    state $layout        = {
        map { $_->[0] => $multiline_pat->new( $_->[1] ) }
            [ stderr  => '%p> %m (in %M() %F, line %L)%n'           ],
            [ dated   => '%d %p> %c %M{1} (%L) | %m%n'              ],
            [ minimal => '%m%n'                                     ],
            [ trace   => '%d %p> $mark   "%c %M{1} (%L)"   $mark%n'
                       . '%d %p> %m  [[ Caller: %l ]]%n'            ],
    };
    return $layout;
}


sub default_filters {
    my $self = shift;
    require Log::Log4perl::Filter::LevelMatch;
    state $filters = {
        TraceOnly => Log::Log4perl::Filter::LevelMatch->new(
                        name          => 'TraceOnly',
                        LevelToMatch  => 'TRACE',
                        AcceptOnMatch => 1,
                    ),
    };
    return $filters;
}

sub default_appenders {
    my $self         = shift;
    my $log_file;
    state $layout   = $self->default_layouts;
    state $appenders = {
        'Stderr' => Log::Log4perl::Appender->new(
                        'Log::Log4perl::Appender::Screen',
                        name         => 'Stderr',
                        stderr       => 1,
                        Threshold    => 'WARN',
                        syswrite     => 1,
                        utf8         => 1,
                        autoflush    => 1,
                        layout       => $layout->{stderr},
                    ),

        'MTLog'  => Log::Log4perl::Appender->new(
                        "MT::Log::Log4perl::Appender::MT",
                        warp_message => 0,
                        layout       => 'Log::Log4perl::Layout::NoopLayout',
                        Threshold    => 'ERROR',
                    ),

        # 'Marker' => Log::Log4perl::Appender->new(
        #                 "Log::Log4perl::Appender::File",
        #                 Filter   => $self->default_filters->{TraceOnly},
        #                 # filename => $log_file,
        #                 mode     => 'append',
        #                 umask    => '0000',
        #                 recreate => 1,
        #                 layout   => $layout->{trace},
        #             ),
        # 
        # 'File'   => Log::Log4perl::Appender->new(
        #                 "Log::Log4perl::Appender::File",
        #                 # filename  => $log_file,
        #                 mode      => 'append',
        #                 umask     => '0000',
        #                 recreate  => 1,
        #                 layout    => $layout->{dated},
        #                 Threshold => 'DEBUG',
        #             ),

    };

    # $appender->layout( $self->default_layouts );
    return $appenders;
}

1;

__END__



####################
#   ROOT LOGGER    #
####################
# The following sets the root logger's level to TRACE (the lowest/noisest level)
# and attaches appenders for output to the log file, the standard error log and
# the activity log.
log4perl.logger                         = TRACE, Marker, File, Errorlog, MTLog

######################
#   LOG FILE PATH    #
######################
# The setting below defines the absolute path to your desired location for the
# Log4MT log file.  This file should exist and have permissions that allow MT
# to write to it.  If in doubt, use 777 (or "rwxrwxrwx").
log_file                                = /usr/local/var/log/log4mt.log

######################
# LAYOUT DEFINITIONS #
######################
layout_class            = Log::Log4perl::Layout::PatternLayout::Multiline
layout_stderr           = %p> %m (in %M() %F, line %L)%n
layout_pattern_dated    = %d %p> %c %M{1} (%L) | %m%n
layout_pattern_minimal  = %m%n
layout_pattern_trace    = %d %p> #########################   "%c %M{1} (%L)"   #########################%n%d %p> %m  [[ Caller: %l ]]%n

#######################
### Marker appender ###
#######################
log4perl.filter.TraceOnly                           = Log::Log4perl::Filter::LevelMatch
log4perl.filter.TraceOnly.LevelToMatch              = TRACE
log4perl.filter.TraceOnly.AcceptOnMatch             = true
log4perl.appender.Marker                            = Log::Log4perl::Appender::File
log4perl.appender.Marker.filename                   = ${log_file}
log4perl.appender.Marker.mode                       = append
log4perl.appender.Marker.umask                      = 0000
log4perl.appender.Marker.recreate                   = 1
log4perl.appender.Marker.layout                     = ${layout_class}
log4perl.appender.Marker.layout.ConversionPattern   = ${layout_pattern_trace}
log4perl.appender.Marker.Filter                     = TraceOnly

#####################
### File appender ###
#####################
log4perl.appender.File                              = Log::Log4perl::Appender::File
log4perl.appender.File.filename                     = ${log_file}
log4perl.appender.File.mode                         = append
log4perl.appender.File.umask                        = 0000
log4perl.appender.File.recreate                     = 1
log4perl.appender.File.layout                       = ${layout_class}
log4perl.appender.File.layout.ConversionPattern     = ${layout_pattern_dated}
log4perl.appender.File.Threshold                    = DEBUG

######################
### MTLog appender ###
######################
log4perl.appender.MTLog                             = MT::Log::Log4perl::Appender::MT
log4perl.appender.MTLog.warp_message                = 0
log4perl.appender.MTLog.layout                      = Log::Log4perl::Layout::NoopLayout
log4perl.appender.MTLog.Threshold                   = ERROR

#######################
### Stderr appender ###
#######################
log4perl.appender.Errorlog                          = Log::Log4perl::Appender::Screen
log4perl.appender.Errorlog.stderr                   = 1,
log4perl.appender.Errorlog.layout                   = ${layout_class}
log4perl.appender.Errorlog.layout.ConversionPattern = ${layout_stderr}
log4perl.appender.Errorlog.Threshold                = WARN
