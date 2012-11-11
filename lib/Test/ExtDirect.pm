package Test::ExtDirect;

use 5.006000;
use strict;
use warnings;

use Exporter;

use Test::More;
use Clone ();

use RPC::ExtDirect::Server;
use RPC::ExtDirect::Client;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    start_server
    stop_server

    call_extdirect
    submit_extdirect
    poll_extdirect

    call_extdirect_ok
    submit_extdirect_ok
    poll_extdirect_ok

    call
    submit
    poll

    call_ok
    submit_ok
    poll_ok
);

our %EXPORT_TAGS = (
    DEFAULT => [qw/
        start_server stop_server call_extdirect call_extdirect_ok
        submit_extdirect submit_extdirect_ok poll_extdirect
        poll_extdirect_ok
    /],

    all => [qw/
        start_server stop_server call_extdirect call_extdirect_ok
        submit_extdirect submit_extdirect_ok poll_extdirect
        poll_extdirect_ok call submit poll call_ok submit_ok poll_ok
    /],
);

our @EXPORT = qw(
    start_server
    stop_server

    call_extdirect
    call_extdirect_ok
    submit_extdirect
    submit_extdirect_ok
    poll_extdirect
    poll_extdirect_ok
);

our $VERSION = '0.2';
$VERSION = eval $VERSION;

our ($SERVER_PID, $SERVER_PORT);

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Starts testing HTTP server and returns the port it listens on
#

sub start_server {
    my (%params) = @_;

    return $SERVER_PORT if $SERVER_PORT;

    my $server = RPC::ExtDirect::Server->new(%params);
    my $port   = $SERVER_PORT = $server->port;

    if ( my $pid = $SERVER_PID = fork ) {
        local $SIG{CHLD} = sub { waitpid $pid, 0 };

        # Give child some time to start
        select undef, undef, undef, 0.1;

        return $port;
    }
    elsif ( defined $pid && $pid == 0 ) {

        # Trap last breaths to avoid cluttering the screen
        local $SIG{__DIE__} = sub {};

        $server->run();

        exit 0;
    }
    else {
        die "Can't fork: $!";
    };

    return;     # Just in case
}

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Stops the running HTTP server instance
#

sub stop_server {
    my $pid = shift || $SERVER_PID;

    # This is a bit kludgy but somehow if I use any other signal
    # the server kid has last opportunity to cry for help.
    # Which we don't want.
    kill 9, $pid if defined $pid;

    $SERVER_PID = $SERVER_PORT = undef;
}

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Instantiate a new RPC::ExtDirect::Client and make a request call
# returning the data
#

sub call_extdirect {
    my (%params) = @_;

    my $action = delete $params{action};
    my $method = delete $params{method};
    my $arg    = Clone::clone( delete $params{arg} );

    my $client = _get_client(%params);
    my $data   = $client->call(action => $action, method => $method,
                               arg    => $arg,    %params);

    return $data;
}

*call = \&call_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run call_extdirect wrapped in eval and fail the test if it dies
#

sub call_extdirect_ok {
    my $result = eval { call_extdirect(@_) };

    _pass_or_fail($@);

    return $result;
}

*call_ok = \&call_extdirect_ok;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Submit a form to Ext.Direct method
#

sub submit_extdirect {
    my (%params) = @_;

    my $action = delete $params{action};
    my $method = delete $params{method};
    my $arg    = Clone::clone( delete $params{arg}    );
    my $upload = Clone::clone( delete $params{upload} );

    my $client = _get_client(%params);
    my $data   = $client->submit(action => $action, method => $method,
                                 arg    => $arg,    upload => $upload,
                                 %params);

    return $data;
}

*submit = \&submit_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run submit_extdirect wrapped in eval, fail the test if it dies
#

sub submit_extdirect_ok {
    my $result = eval { submit_extdirect(@_) };

    _pass_or_fail($@);

    return $result;
}

*submit_ok = \&submit_extdirect_ok;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Poll Ext.Direct event provider and return data
#

sub poll_extdirect {
    my (%params) = @_;

    my $client = _get_client(%params);
    my $data   = $client->poll(%params);

    return $data;
}

*poll = \&poll_extdirect;

### PUBLIC PACKAGE SUBROUTINE (EXPORT) ###
#
# Run poll_extdirect wrapped in eval, fail the test if it dies
#

sub poll_extdirect_ok {
    my $result = eval { poll_extdirect(@_) };

    _pass_or_fail($@);

    return $result;
}

*poll_ok = \&poll_extdirect_ok;

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Initializes RPC::ExtDirect::Client instance
#

sub _get_client {
    my (%params) = @_;

    my $class = 'RPC::ExtDirect::Client';

    $params{static_dir} ||= '/tmp';

    my $host = $params{host} || '127.0.0.1';
    my $port = $params{port} || start_server(%params);

    my $client = $class->new(host => $host, port => $port);

    return $client;
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Pass or fail a test depending on $@
#

sub _pass_or_fail {
    my ($err) = @_;

    my ($calling_sub) = (caller 0)[3];

    if ( $err ) {
        fail "$calling_sub failed: $err";
    }
    else {
        pass "$calling_sub successful";
    };
}

END { stop_server }

1;

__END__

=pod

=head1 NAME

Test::ExtDirect - An easy and convenient way to test Ext.Direct classes

=head1 SYNOPSIS

With default imports:

    use Test::ExtDirect;
    
    my $data = call_extdirect(action  => 'Action',
                              method  => 'Method',
                              arg     => { foo => 'bar' },
                              cookies => { bar => 'baz' });
    
    $data = submit_extdirect(action => 'Action',
                             method => 'form_handler',
                             arg    => { field1 => 'value1' });
    
    $data = poll_extdirect();

Or:

    use Test::ExtDirect qw(:all);
    
    my $data = call(...);
    $data    = submit(...);
    $data    = poll();

=head1 DESCRIPTION

This module provides a set of utility functions for testing Ext.Direct
classes. For each test script, an instance of L<RPC::ExtDirect::Server>
will be created, and requests will be made with L<RPC::ExtDirect::Client>.

This way you can simulate actual Ext JS or Sencha Touch client code making
calls, submitting forms, uploading files, or polling events. Such testing
provides additional layer of insurance against Ext.Direct specific problems
and errors that may otherwise creep into the codebase.

=head1 SUBROUTINES

Test::ExtDirect provides the following subroutines:

=over 4

=item start_server(%params)

Starts a new RPC::ExtDirect::Server instance. It is not necessary to call
this function directly, call/submit/poll will launch a new server if it's
not done yet.

Parameters are accepted as hash and passed on to server constructor.
See L<RPC::ExtDirect::Server> for details.

Returns port number that server listens on.

=item stop_server

Stops the server instance used for testing. Again it's not necessary to call
this function explicitly, the server will be shut down when all tests are
finished.

=item call_extdirect(%params)

Call Ext.Direct remoting method. Parameters:

=over 8

=item action

Ext.Direct Action (class) name.

=item method

Ext.Direct Method name.

=item arg

Method arguments; either arrayref for Methods that accept ordered arguments
or hashref for Methods that request named arguments.

=item ...

Any other parameters are passed to client constructor. See
L<RPC::ExtDirect::Client> for details.

=back

Returns whatever data is returned by Method.

=item submit_extdirect

Submit an Ext.Direct form request. Takes the following parameters:

=over 8

=item action, method, arg

The same as with L</call_extdirect>, see above.

=item upload

Arrayref of file paths to upload with that request.

=back

Returns the data passed on by Method.

=item poll_extdirect

Poll the server for events. Does not take any parameters.

Returns arrayref with event data. When there are no events ready (if you
test this case), a single __NONE__ event will be returned. This is to avoid
breaking Ext JS code that throws an exception if no events are returned by
the server.

=back

=head1 EXPORT

By default, the following functions are exported:

=over 4

=item start_server

=item stop_server

=item call_extdirect

=item submit_extdirect

=item poll_extdirect

=back

There are short-named versions that are not exported by default to avoid
collisions. They can be added with :all tag:

=over 4

=item call

Points to call_extdirect.

=item submit

Points to submit_extdirect.

=item poll

Points to poll_extdirect.

=back

For each of call*, submit* and poll*, there is similarly named *_ok
function that wraps its respective namesake in eval(), passing or
failing additional test depending $@.

=head1 DEPENDENCIES

Test::ExtDirect is dependent on the following modules: L<Clone>,
L<Test::More>, L<RPC::ExtDirect::Server>, L<RPC::ExtDirect::Client>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems to author,
patches are welcome.

=head1 SEE ALSO

For more information on developing Ext.Direct code in Perl, see
L<RPC::ExtDirect>.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I would like to thank IntelliSurvey, Inc for sponsoring my work
on this module.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 by Alexander Tokarev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<"perlartistic">.

=cut

