package TestsFor::MT::Logger;
use Test::Class::Moose;

sub test_startup {
    my ( $test, $report ) = @_;
    $test->test_skip("I don't want to run this class");
}

1;
