package Log4MT;

use Moo;
    extends 'MT::Logger::Log4perl';

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

Log::Log4perl->wrapper_register( __PACKAGE__ );

1;