#!/usr/bin/env perl
package Test::MT::Logger::Log4perl::useimport;

use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use Package::Stash;
use DDP;
use Carp::Always;

use MT::Logger::Log4perl  ();
use Log::Log4perl::Logger ();
use Log::Log4perl::Level  ();

our @export_tests = qw(
    easycarpers
    easyloggers
    get_logger
    levels
    no_extra_logdie_message
    nostrict
    nowarn
    resurrect
);

sub import {
    feature->( 5.010 );
    strict->import();
    warnings->import( FATAL => 'all' );
    Test::More->import;
}

sub no_use_exception { is(   $_[1], undef, 'No exception on use'      ) }
sub    use_exception { isnt( $_[1], undef, 'Exception thrown in use!' ) }


sub has (@) {
    my $self      = shift;
    my @tests     = @_;
    my %tests_run = map { $_ => 0 } @export_tests;

    note "Testing that $self->has: \n\t =>".join(', ',@tests);

    foreach my $e ( @tests ) {
        my $test = "test_$e";
        ok( $self->$test, "$test" )
            || return fail( "bailing out of has after $test" );
        $tests_run{$e} = 1;
    }
    return $self->hasnt( grep { ! $tests_run{$_} } keys %tests_run );
}


sub hasnt (@) {
    my $self  = shift;
    my @tests = @_;

    note "Testing that $self->hasnt:\n\t=> ".join(', ',@tests);

    foreach my $test ( map { "test_$_" } @tests ) {
        my $res = $self->$test();
        unless ( ok( ! $res, "$test" ) ) {
            warn "$test failed. Bailing out of hasnt loop";
            return 0;
        }
    }
    return 1;
}

sub package_has($$;$) {
    my ( $pkg, $var, $expect ) = @_;

    my $stash = Package::Stash->new($pkg)
        or die "Could not get stash of $pkg";

    return $stash->has_symbol($var)
        && defined( $stash->get_symbol($var) ) ? 1 : 0;
}

sub test_levels {
    my $pkg = shift;
    my $cnt = 0;
    foreach my $level ( keys %Log::Log4perl::Level::PRIORITY ) {
        my $ok = $pkg->package_has( '$'.$level, 
                        $Log::Log4perl::Level::PRIORITY{$level});
        $cnt++ if $ok;
    }
    return ( $cnt == scalar keys %Log::Log4perl::Level::PRIORITY );
}

sub test_get_logger { shift->package_has( "\&get_logger" ) }

sub test_easyloggers {
    my $pkg    = shift;
    my $cnt    = 0;
    my @levels = qw(TRACE DEBUG INFO WARN ERROR FATAL ALWAYS);
    foreach my $level ( @levels ) {
        my $ok = $pkg->package_has( '&'.$level );
        $cnt++ if $ok;
    }
    return ( $cnt == @levels );
}

sub test_easycarpers {
    my $pkg = shift;
    my $cnt = 0;
    my @levels = qw( LOGCROAK LOGCLUCK LOGCARP LOGCONFESS LOGDIE LOGEXIT LOGWARN);
    foreach my $level ( @levels ) {
        my $ok = $pkg->package_has( '&'.$level );
        $cnt++ if $ok;
    }
    return ( $cnt == @levels );
}

sub test_nowarn         {
    $Log::Log4perl::Logger::NON_INIT_WARNED         || 0 == 1   }

sub test_nostrict       {
    $Log::Log4perl::Logger::NO_STRICT               || 0 == 1   }

sub test_no_extra_logdie_message {
    not ( $Log::Log4perl::LOGDIE_MESSAGE_ON_STDERR  || 0 == 0 ) }

sub test_resurrect      { return shift->is_resurrected }

1;

__END__

