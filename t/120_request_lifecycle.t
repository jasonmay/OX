#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request;

my $n = 0;
{
    package Thing;
    use Moose;

    sub BUILD { ++$n }
}

{
    package Foo::Root;
    use Moose;

    has thing => (
        is       => 'ro',
        isa      => 'Thing',
        required => 1,
    );

    sub index { $n }
}

{
    package Foo;
    use OX;

    has thing => (
        is        => 'ro',
        isa       => 'Thing',
        lifecycle => 'Request',
    );
    has root => (
        is           => 'ro',
        isa          => 'Foo::Root',
        lifecycle    => 'Request',
        dependencies => ['thing'],
    );

    router as {
        route '/' => 'root.index'
    }, (root => depends_on('root'));
}

test_psgi
    app => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        for (1 .. 2) {
            my $req = HTTP::Request->new(GET => "http://localhost");
            my $res = $cb->($req);
            is($res->content, $_);
        }
    };

done_testing;
