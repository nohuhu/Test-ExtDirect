use ExtUtils::MakeMaker;

# Add the `devtest` target to run regression and POD tests in one go
sub MY::postamble {
    return <<'END';
devtest :
	REGRESSION_TESTS=1 POD_TESTS=1 $(MAKE) test

END
}

# Override `disttest` so it would behave as `devtest`
sub MY::dist_test {
    return <<'END';
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) devtest $(PASTHRU)

END
}

my $MM_VERSION = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Test::ExtDirect',
    VERSION_FROM      => 'lib/Test/ExtDirect.pm',
    
    ($MM_VERSION >= 6.5503
        ? ( BUILD_REQUIRES => {
                'Test::More' => 0,
            },
            PREREQ_PM      => {
                'RPC::ExtDirect::Server' => '1.00',
                'RPC::ExtDirect::Client' => '1.00',
            },
        )
        : ( PREREQ_PM => {
                'Test::More'             => 0,
                'RPC::ExtDirect::Server' => '1.00',
                'RPC::ExtDirect::Client' => '1.00',
            },
        ),
    ),

    ABSTRACT => 'An easy and convenient way to test Ext.Direct code',
    AUTHOR   => 'Alex Tokarev <tokarev@cpan.org>',
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

