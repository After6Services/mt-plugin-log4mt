package MT::Log::Log4perl::Appender::MT::Mail;

use Moo;
    extends qw(Log::Log4perl::Appender);

use Try::Tiny;
use Carp qw( cluck confess longmess );
use MT::Logger::Log4perl qw( get_logger );

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

has 'app' => (
    is      => 'ro',
    isa     => 'MT::App',
    lazy    => 1,
    builder => 1,
);

has 'from' => (
    is      => 'ro',
    isa     => 'EmailAddress',
    lazy    => 1,
    builder => 1,
);

has 'content_type' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => 1,
);

has 'default_recipient' => (
    is      => 'ro',
    isa     => 'EmailAddress',
    lazy    => 1,
    builder => 1,
);

sub _build_app {
    my $app = MT->instance if try { ref $MT::mt_inst };
    unless ( $app ) {
        confess 'Log4MT attempted to send email via MT::Mail before '
              . 'MT was initialized ';
    }
    $app;
}

sub _build_from {
    my $self = shift;
    my $app  = $self->app;
    my $from;
    unless ( $from = $app->config->EmailAddressMain ) {
        my $msg = __PACKAGE__ . " failure: "
                . MT->translate('System Email Address is not configured.');
        $app->log({
            message  =>  $msg,
            level    => MT::Log::ERROR(),
            class    => 'system',
            category => 'email'
        });
        cluck $msg;
        return;
    }
    
}

sub _build_default_recipient { shift()->from }

sub _build_content_type {
    my $self = shift;
    my $app  = $self->app;
    my $charset = $app->config->MailEncoding || $app->config->PublishCharset;
    return qq(text/plain; charset="$charset");
}

sub log { ## no critic
    my ( $self, %params ) = @_;
    my $app     = $self->app;
    my $from    = $self->from;
    my $to      = $params{to} // $params{To} // $self->default_recipient;
    my $body    = $params{message};
    my $subject = $params{subject}
               // $params{Subject}
               // $params{log4p_level} .': '.$params{log4p_category};

    return unless $from && $to && $body && $subject;

    require MT::Mail;
    MT::Mail->send(
        {
            'Content-Type' => $self->content_type,
            From           => $from,
            To             => $to,
            Subject        => $subject,
        },
        $body,
    )
        or die MT::Mail->errstr();
    1;
}

1;

