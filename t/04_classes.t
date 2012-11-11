# Test using custom classes instead of RPC::ExtDirect::Server/Client

use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More tests => 2;

use Test::ExtDirect;

use lib 't/lib';

my $port = start_server(
    server_class => 'RPC::ExtDirect::Server::Foo',
    static_dir   => '/tmp/',
);

# To avoid "variable used only once" warning
my $server_started = $RPC::ExtDirect::Server::Foo::server_started
                   = $RPC::ExtDirect::Server::Foo::server_started;

is $server_started, 1, "Server class";

my $client = Test::ExtDirect::_get_client(
    host         => 'localhost',
    port         => $port,
    client_class => 'RPC::ExtDirect::Client::Foo',
);

is ref $client, 'RPC::ExtDirect::Client::Foo', "Client class";

