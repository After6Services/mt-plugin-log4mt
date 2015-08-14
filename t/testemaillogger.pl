#!/usr/bin/env perl

package LDAPTools::Email::Tester;

use strict;
use warnings;
use lib qw( addons/Log4MT.plugin/lib lib extlib );
use MT::Logger::Log4perl qw( get_logger :resurrect l4mtdump :levels );
use Data::Dumper;

use MT;
my $app = MT->new();

my $logger = get_logger('mtmail');
print STDERR Dumper($logger);

my $a = Log::Log4perl->appender_by_name('MTMail');
print STDERR Dumper($a);

print STDERR Dumper $logger->warn(
    subject => 'Test: No from/to',
    message => 'This is a test email. Please ignore',
);

print STDERR Dumper $logger->warn(
    to      => 'jay+recip@endevver.com',
    subject => 'Test: No to',
    message => 'This is a test email. Please ignore',
);

print STDERR Dumper $logger->warn(
    from    => 'jay@endevver.com',
    subject => 'Test: No to',
    message => 'This is a test email. Please ignore',
);

print STDERR Dumper $logger->warn(
    from    => 'jay@endevver.com',
    to      => 'jay+recip@endevver.com',
    subject => 'Test: Both from/to',
    message => 'This is a test email. Please ignore',
);

1;
