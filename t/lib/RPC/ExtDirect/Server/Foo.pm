package RPC::ExtDirect::Server::Foo;

use base 'RPC::ExtDirect::Server';

our $server_started;

sub new {
    my ($class, %params) = @_;

    $server_started = 1;

    return $class->SUPER::new(%params);
}

1;

