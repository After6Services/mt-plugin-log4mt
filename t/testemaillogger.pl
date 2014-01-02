#!/usr/bin/env perl

package LDAPTools::Email::Tester;

use strict;
use warnings;
use lib qw( addons/Log4MT.plugin/lib lib extlib );
use MT::Logger::Log4perl qw( get_logger :resurrect l4mtdump :levels );
use Data::Printer;

use MT;
my $app = MT->new();

my $logger = get_logger('mtmail');
p $logger;

my $a = Log::Log4perl->appender_by_name('MTMail');
p $a;

p $logger->warn(
    subject => 'Test: No from/to',
    message => 'This is a test email. Please ignore',
);

p $logger->warn(
    to      => 'jay+recip@endevver.com',
    subject => 'Test: No to',
    message => 'This is a test email. Please ignore',
);

p $logger->warn(
    from    => 'jay@endevver.com',
    subject => 'Test: No to',
    message => 'This is a test email. Please ignore',
);

p $logger->warn(
    from    => 'jay@endevver.com',
    to      => 'jay+recip@endevver.com',
    subject => 'Test: Both from/to',
    message => 'This is a test email. Please ignore',
);

1;
