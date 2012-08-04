use 5.006000;
use ExtUtils::MakeMaker;

my $MM_VERSION = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Test::ExtDirect',
    VERSION_FROM      => 'lib/Test/ExtDirect.pm',

    PREREQ_PM         => {
        'Clone'                  => 0,
        'Test::More'             => 0,
        'RPC::ExtDirect::Server' => 0,
        'RPC::ExtDirect::Client' => 0,
    },

    ABSTRACT => 'An easy and convenient way to test Ext.Direct classes',
    AUTHOR   => 'Alexander Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',

    ($MM_VERSION >= 6.46
        ? ( META_MERGE => {
                resources => {
                    bugtracker => 'http://github.com/nohuhu/Test-ExtDirect/issues',
                    repository => 'http://github.com/nohuhu/Test-ExtDirect',
                },
            },
        )
        : ()
    ),
);

