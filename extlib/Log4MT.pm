package Log4MT;

use Moo;
    extends 'MT::Logger::Log4perl';

Log::Log4perl->wrapper_register( __PACKAGE__ );

1;