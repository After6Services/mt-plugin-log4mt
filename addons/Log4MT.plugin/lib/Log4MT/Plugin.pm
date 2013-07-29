package Log4MT::Plugin;

use 5.010_001;
use strict;
use warnings;
use Data::Dumper;
use Carp qw( croak confess longmess );
use Path::Tiny;
use Try::Tiny;
use MT::Logger::Log4perl qw( :resurrect get_logger l4mtdump );
use Carp::Always;

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

our ( $l4p, $mtlog );

sub init {}

sub post_init {
    my $cb  = shift;
    my $app = shift;
    my $conf = try { path(( $ENV{MT_HOME} // $app->mt_dir ), 'log4mt.conf' ) };
    return MT::Logger::Log4perl->reinitialize( $conf )
        if $conf && $conf->is_file;
    warn "No log4mt.conf file found in MT dir";
}

sub init_request {
    my $plugin = shift;
    my $app    = shift;
    my $q      = try { $app->query } || $app->param;
    ###l4p $l4p ||= get_logger(); $l4p->trace('init_request');

    unless (   $q->param('password')
            && grep { $q->param($_) } qw( username old_pass hint ) ) {

        ###l4p $l4p->info( 'App query: ', l4mtdump( $q ));
        return;
    }
    ###l4p $l4p->info( 'App query for mode ', ($app->mode||''),
    ###l4p              'NOT LOGGED DUE TO LOGIN CREDENTIALS'   );
}


sub show_template_params {
    ###l4p my ( $cb, $app, $param, $tmpl ) = @_;
    ###l4p $l4p ||= get_logger();
    ###l4p
    ###l4p my @msgs;
    ###l4p if ( scalar keys %$param ) {
    ###l4p     unless ( $app->request('Log4MT_template_params_output') ) {
    ###l4p         $l4p->trace('show_template_params');
    ###l4p         push( @msgs, 'Initial outgoing template parameters: ' );
    ###l4p         push( @msgs,
    ###l4p             map {
    ###l4p                 sprintf( "\t%-30s %s", ($_//''), ($param->{$_}//''))
    ###l4p             } sort keys %$param
    ###l4p         );
    ###l4p         $app->request( 'Log4MT_template_params_output', 1 );
    ###l4p     }
    ###l4p }
    ###l4p my $f = 'template_filename';
    ###l4p push( @msgs, "Loading app template ".($param->{$f} // "[$f is NULL]" ));
    ###l4p
    ###l4p $l4p->debug($_) foreach @msgs;
}

sub hdlr_logger {
    my ( $ctx, $args ) = @_;
    my $tag            = $ctx->stash('tag');
    ###l4p $l4p ||= get_logger(); $l4p->trace();

    # Get logger message from attribute or content of block and trim
    my @msgs = map { s/(^\s+|\s+$)//g; $_ } (
        $tag eq 'Logger' ? $args->{message} : __block_text( @_ )
    );

    # Get logger from category, logger attribute or use default logger
    my $category
        = join( '.', 'MTLogger.Template',
                     ( $args->{logger} // $args->{category} // () ));

    my $tmpl_logger = get_logger($category);
    my $level       = $tmpl_logger->level( uc( $args->{level} || 'INFO' ) );
    $tmpl_logger->log( $level, $_ ) foreach @msgs;
    return '';
}


sub __block_text {
    my ($ctx, $args) = @_;
    my $str      = $ctx->stash('uncompiled');
    my $compile  = $args->{compile};
    $compile   //= defined $args->{uncompiled} ? ! $args->{uncompiled} : 1;

    my @msgs;
    if ($compile) {
        # Process enclosed block of template code
        my $tokens = MT::Template::Context::_hdlr_pass_tokens(@_);
        if (defined $tokens) {
            if ( my $ph = $ctx->post_process_handler ) {
                my $content = $ph->( $ctx, $args, $tokens );
                $str = $content;
            }
        }
        $str =~ s/(^\s+|\s+$)//g;
        push( @msgs, split( /\n/, $str//'' ) );
    } ## end else [ if ( $tag eq 'Logger' )]

    return @msgs;
}

1;
