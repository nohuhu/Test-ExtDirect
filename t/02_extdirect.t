use strict;
use warnings;

package test::class;

use RPC::ExtDirect Action => 'test';

use RPC::ExtDirect::Event;

sub echo : ExtDirect(3) {
    my $class = shift;

    return [ splice @_, 0, 3 ];
}

sub handle_form : ExtDirect(formHandler) {
    my ($class, %arg) = @_;

    delete $arg{_env};

    my @fields = grep { !/^file_uploads$/ } keys %arg;

    my %result;
    @result{ @fields } = @arg{ @fields };

    return \%result;
}

our $EVENT = { name => 'foo', data => 'foo bar' };

sub handle_poll : ExtDirect(pollHandler) {
    return RPC::ExtDirect::Event->new($EVENT->{name}, $EVENT->{data});
}

package main;

use Test::More tests => 7;

use_ok 'Test::ExtDirect';

my $echo_data = [ 'foo', [ 'foo', 'bar' ], { foo => 'bar' } ];

my $ret_data = eval {
     call_extdirect(action => 'test', method => 'echo', arg => $echo_data)
};

is        $@,        '',         "Echo didn't die";
is_deeply $ret_data, $echo_data, "Echo data matches";

my $form_data = { foo_field => 'foo', bar_field => 'bar' };

$ret_data = eval {
    submit_extdirect(action => 'test', method => 'handle_form',
                     arg => $form_data)
};

is        $@,        '',         "Form didn't die";
is_deeply $ret_data, $form_data, "Form data matches";

my $poll_data = $test::class::EVENT;

$ret_data = eval { poll_extdirect() };

is        $@,        '',         "Poll didn't die";
is_deeply $ret_data, $poll_data, "Poll data matches";

