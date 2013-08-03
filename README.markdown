# Log4MT - A plugin for Movable Type v4 and Melody #

* **AUTHOR:**     Jay Allen, Endevver LLC, http://endevver.com
* **LICENSE:**    GNU Public License v2
* **DATE:**       07/29/2013

The Log4MT plugin enhances Movable Type with the
[fantastic and ultra-powerful Log4Perl logging framework][Log4perl]. Like
Log4perl, Log4MT enables you to debug your code, handle exceptions or send
notifications with one of six priorities (trace, debug, info, warn, error, fatal).

The output of those messages can go to any of the following:

* The webserver error log
* An arbitrary file
* Any database
* Any socket
* One or more arbitrary email addresses
* The syslog
* ...and many more! 

What's more, with Log4MT you can completely control not only the formatting of
those messages but also exert granular control over what messages should
trigger output, which output methods they should trigger or which messages
should be ignored altogether.

For an overview on Log4MT's capabilities, see the excellent overview of
Log::Log4perl "[Retire your debugger, log smartly with Log::Log4perl!][]"

## VERSION ##

1.9.17 (currently in beta)

## REQUIREMENTS ##

* [Movable Type 4.x or greater][mt] or any version of [Melody][]
* See INSTALLATION for CPAN dependencies

## LICENSE ##

This program is distributed under the terms of the GNU General Public License, version 2.

## INSTALLATION ##

1. Install the following CPAN distributions, which are no longer included in
   this repository
    * Log::Dispatch
    * Log::Log4perl
    * Moo
    * strictures
    * MooX::Singleton
    * Sub::Install
    * Sub::Quote
    * Path::Tiny
    * Carp::Always
    * Data::Printer
    * Import::Into
    * Class::Method::Modifiers
2. Clone the repository or [download the latest version][download] and
   unpack the archive
3. Copy (or symlink) the contents of the `addons` and `extlib` directories in
   the archive into the respective directories in your [MT][]/[Melody][]
   application directory. In the case of `extlib/MT`, the directory already
   exists but the files being added are new.
4. Copy the `log4mt.conf` file to the root of your MT directory
5. Modify the `log4mt.conf` file to specify the desired absolute path to your
   log file. There are instructions inside the file which will guide you.

We recommend using [cpanm][] for installation of CPAN modules, not only
because it's awesome, but also because it supports local::lib installation of
depdendencies for those who do no have root privileges on their systems.

    cpanm Sub::Install Sub::Quote Log::Dispatch Log::Log4perl    \
          MooX::Singleton Path::Tiny Moo Carp::Always strictures \
          Data::Printer Import::Into Class::Method::Modifiers
    
And that's it!

## UPGRADING ##

Although we strongly recommend you use the new logging initialization syntax
(using MT::Logger::Log4perl) shown in the USAGE section below in any new code,
we've tried our best to keep backwards compatibility to older versions.

If you are upgrading from a version earlier than v1.9.0, you will not have to
change the use statements, logger initialization or logging statements in your
code, which most likely look something like this:

    # The easy way
    our $logger ||= MT::Log->get_logger()

    # Or, before MT initialization...
    use MT::Log::Log4perl;
    our $logger = MT::Log::Log4perl->new();

    # Or, even this, with all the bells and whistles...
    use Log::Log4perl qw( :resurrect );
    ###l4p use MT::Log::Log4perl qw( l4mtdump );
    ###l4p our $logger ||= MT::Log::Log4perl->new();

That said, you **will** have to make changes to your current `log4mt.conf`
file to match the configuration of the default loggers and appenders shown in
the bundled [log4mt.conf](log4mt.conf). To avoid any problems, it's best to
**start with the bundled config** and port any additions or changes (e.g. your
log path, any custom logging levels, etc) you made from your current config to
it.

## USAGE ##

Using Log4MT in a basic way (i.e. to log messages to a file) is simple. Follow
the installation instructions linked to above and then add the following to
your code:

    use MT::Logger::Log4perl [ @IMPORTS ]

The @IMPORTS are exactly the same as those you'd use when using Log::Log4perl
directly.  For example:

* [`get_logger`][]
* [:resurrect][]
* [:easy][]
* [`:levels`][]
* [`:no_extra_logdie_message`][]
* `:no_strict`
* And others. See the [Log::Log4perl documentation][] for more.

[`:no_extra_logdie_message`]:
   https://metacpan.org/module/Log::Log4perl#Dirty-Tricks
[`:levels`]:
   https://metacpan.org/module/Log::Log4perl#Log-Levels
[`get_logger`]:
   https://metacpan.org/module/Log::Log4perl#Shortcuts
[:easy]:
   https://metacpan.org/module/Log::Log4perl#Easy-Mode
[:resurrect]:
   https://metacpan.org/module/Log::Log4perl#Resurrecting-hidden-Log4perl-Statements

Additionally, Log4MT provides one additional import, `l4mtdump`, that installs
a function of the same name which you can (and should) use to serialize
objects, references and other complex scalars (see example below).

Once you use MT::Logger::Log4perl, whenever you need to log something, you
simply do the following:

    my $logger = get_logger();
    $logger->trace('I am here');

You can replace `trace` with any of the Log4perl levels—`debug`, `info`,
`warn`, `error` or `fatal`—or any of the other logger functions described in
the [Log::Log4perl documentation][] (e.g. [`is_debug`][], [`less_logging`][])

    $logger->debug('This is a debug statement');
    $logger->info('FWIW, this is interesting...');
    $logger->warn('User doesn't have a display name: ', $author->name);
    $logger->error('Ran into an error saving entry: ', l4mtdump($entry));
    $logger->fatal(sprintf 'Application %s died with error "%s"',
        ref($app), ($app->errstr || $@));

The `trace` function is somewhat special in that it additionally logs some
information about the location of the logging call as well as characters which
help to set it off from the rest.  This is best used at the top of a method.

[`is_debug`]:
   https://metacpan.org/module/Log::Log4perl#Log-Levels
[`less_logging`]:
   https://metacpan.org/module/Log::Log4perl#Changing-the-Log-Level-on-a-Logger

## CONFIGURATION ##

For most users, the basic configuration is enough to get you started logging.
If, however, you want to turn down the logging level without removing your
logging statements or do some more exotic things, the `log4mt.conf` file is the
heart of the an incredible amount of functionality.

Everything you can do with the config file to customize Log4MT is documented
in the [Log::Log4perl documentation][].

## ADVANCED FEATURES ##

Coming soon...

## FURTHER READING ##

* [Retire your debugger, log smartly with Log::Log4perl!][]
* [Log::Log4perl documentation][]
* [The exhaustive Log::Log4perl FAQ][]
* POD documentation forthcoming 

## VERSION HISTORY ##

Full details can be found in the [commit logs][] but briefly:

* 2010/05/18 - Release of v1.7
* 2008/11/03 - Release of v1.5
* 2008/04/03 - Release of v1.2 beta 2, small but critical bug fix in the configuration file
* 2008/04/02 - Initial public release of v1.2-beta 

[commit logs]: http://github.com/endevver/mt-plugin-log4mt/commits/master

## AUTHOR ##

This plugin was brought to you by [Jay Allen][], Principal and Chief Architect
of [Endevver LLC][]. I hope that you get as much use out of it as I have.


[Log4perl]:
   http://log4perl.sourceforge.net/

[Retire your debugger, log smartly with Log::Log4perl!]:
   http://www.perl.com/pub/a/2002/09/11/log4perl.html

[Log::Log4perl documentation]:
   http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl.html

[The exhaustive Log::Log4perl FAQ]:
   http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl/FAQ.html

[Jay Allen]:
   http://jayallen.org

[Endevver LLC]:
   http://endevver.com

[Melody]:
   http://openmelody.org

[MT]:
   http://movabletype.org

[download]:
   https://github.com/endevver/mt-plugin-log4mt/downloads

[cpanm]:
   https://metacpan.org/module/MIYAGAWA/App-cpanminus-1.6934/bin/cpanm
