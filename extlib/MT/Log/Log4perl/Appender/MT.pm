# Back-compat
package MT::Log::Log4perl::Appender::MT;

use parent qw( MT::Log::Log4perl::Appender::MT::Log );

# Must be on one line so MakeMaker can parse it.
use Log4MT::Version;  our $VERSION = $Log4MT::Version::VERSION;

1;
