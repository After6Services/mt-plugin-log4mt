# $Id: Config.pm 804 2008-02-14 22:56:05Z jay $

package MT::Log::Log4perl::Config;

use strict; use warnings; use Data::Dumper;

use MT::Log::Log4perl::Util qw( err emergency_log trace );

our $INITIALIZED;
sub initialized {
    $_[0]->{initialized} = $INITIALIZED = $_[1];
}

sub new {
    my $class = shift;
    trace();
    my $self = bless {}, $class;
    $self->init(@_);
    $self;
}

sub init {
    my ($self, $args) = @_;
    trace();
    my ($config, $config_response, $class, @eval_msgs);

    # use MT::Request;
    # my $r = MT::Request->instance;
    # $r->cache('foo', $foo);
    # 
    # ## Later and elsewhere...
    # my $foo = $r->cache('foo');


    # TODO  Finish other configurators and reorder the choices.
    #       The order below is not ideal but had to be done to
    #       solve a boostrapping problem where Log4perl either could
    #       not be used until MT was fully initialized
    foreach my $type (qw(file basic mtconfig webui)) {
        eval {
            $config = '';
            $class = join("::", 'MT::Log::Log4perl::Config', $type);
            push @eval_msgs, "Trying $class configuration";
            eval "require $class;";
            if ($config = $class->load($args)) {
                push @eval_msgs, "CONFIG: $config";
                require Log::Log4perl::Config;
                Log::Log4perl::Config->init($config)
                    or die "Configuration rejected by Log::Log4perl";
            }
        };
        err($_) foreach @eval_msgs;
        if ($@) { warn "Warning: $@" and next; } else { $config_response++ }                
        last if $config_response;
    }
    err("Config class being used: $class") if $config_response;
    err("\$config_response = $config_response");

    return $config_response ? $self : undef;
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

sub config_file {
    my ($self, $file) = @_;
    trace();

    # Return previously defined config file if the caller is asking for it
    return $self->{_config_file} if ! defined $file or $file eq '';

    my $cfg;

    # Prepend the MT config directory if relative path
    if (substr($file, 0, 1) ne '/') {
        require File::Spec;
        $file = File::Spec->catfile($self->mt_cfg_dir, $file);
    }
    # Check file and send to Log::Log4perl::Config if valid
    if ($file = can_read_file($file)) {
        # Eval the procedure to catch any errors locally
        local $@;
        eval {  die 'No valid config file found' unless defined $file;
                require Log::Log4perl::Config;
                Log::Log4perl::Config->init_and_watch($file);
                1;
            };
        # In case of error, log and return
        if ($@) {
            emergency_log("Error loading config file: $@");
            return undef;
        }
    }
    # Config file loaded successfully. Set the attribute
    $self->{_config_file} = $file;
}

sub config_data {
    my $self = shift;
    my $data = (@_ > 1) ? { @_ } : shift;
    trace();

    if (! defined $data) {
        # Return previously defined config file if
        # the caller is asking for it
        return $self->{_config} if $self->{_config};

        # No data previously defined or passed in.
        # Fall back to basics.
        $data = $self->basic_config;
    }

    $data = \$data unless ref($data);

    # Eval the procedure to catch any errors locally
    local $@;
    eval {  die 'No valid config data found' unless defined $data;
            require Log::Log4perl::Config;
            Log::Log4perl::Config->init($data);
            1;
        };
    # In case of error, log and return
    if ($@) {
        emergency_log("Error loading config data: $@");
        return undef;
    }
    $self->{_config} = $data;
}

sub mt_cfg_dir {
    eval "require MT;";
    return if $@;

    my $mt = MT->instance;
    if (! $mt) {
        emergency_log('Could not retrieve MT or MT app instance: '.MT->errstr);
        return;
    }

    my $cfg_dir;
    foreach ($mt->config_dir, $mt->mt_dir, $ENV{MT_HOME}) {
        $cfg_dir = can_read_dir($_);
        last if $cfg_dir;
    }
    $cfg_dir;
}

sub can_read_file { _can_read('f', @_) }
sub can_read_dir  { _can_read('d', @_) }
sub _can_read   { 
    shift if ref($_[0]);
    my ($type, $item) = @_;
    return unless defined $item and defined $type;
    my $is_type = ($type eq 'd' and -d $item) ? 1
                : ($type eq 'f' and -f $item) ? 1
                                              : 0;
    return $item if $is_type and -r $item;
}


1;

__END__





Log::Log4perl->init(\ <<'EOT');

# Log4MT configuration file
# AUTHOR:   Jay Allen, Endevver Consulting
# See README.txt in this package for more details
# $Id$
#
# QUICKSTART: Simply specify a path to your preferred location for the Log4MT
#             log file (see log_file below).  This file will be used exclusively
#             for output using the default settings.

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
log_file                                = /PATH/TO/log4mt.log

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

EOT



