package Log4MT::Version;

use version 0.77; our $VERSION = qv('v1.9.11');

=head1 NAME

Log4MT::Version - The MT::Logger::Log4perl project-wide version number

=head1 SYNOPSIS

    package MT::Logger::Log4perl::Whatever;

    # Must be on one line so MakeMaker can parse it.
    use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;


=head1 DESCRIPTION

Because of the problems coordinationg revision numbers in a distributed
version control system and across a directory full of Perl modules, this
module provides a central location for the project's release number.

=cut

1;
