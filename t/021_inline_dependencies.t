#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Bar::Middleware;
    use Moose;
    use MooseX::NonMoose;

    extends 'Plack::Middleware';

    sub call {
        my $self = shift;
        my ($env) = @_;
        my $res = $self->app->($env);
        $res->[2]->[0] = uc($res->[2]->[0]);
        return $res;
    }
}

{
    package Bar;
    use OX;

    router as {
        route '/baz' => sub { "/bar/baz" };
    };
}

{
    package Foo::Root;
    use Moose;

    has [qw(foo bar)] => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    sub index {
        my $self = shift;
        return "Foo::Root::index: " . $self->foo . ' ' . $self->bar;
    }
}

{
    package Foo;
    use OX;

    has foo => (
        is  => 'ro',
        isa => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('param');
        },
        dependencies => {
            param => service('foo_param'),
        },
    );

    has bar => (
        is => 'ro',
        isa => 'Str',
        block => sub {
            my $s = shift;
            return $s->param('param');
        },
        dependencies => {
            param => service('bar_param'),
        },
    );

    has root => (
        is => 'ro',
        isa => 'Foo::Root',
        dependencies => ['foo', 'bar'],
    );

    router as {
        route '/foo' => 'root.index';

        mount '/bar' => 'Bar' => (
            middleware => service(block => sub { ['Bar::Middleware'] }),
        );
    }, (root => service(class => 'Foo::Root', dependencies => ['foo', 'bar']));

}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'Foo::Root::index: foo_param bar_param',
               "right content for /foo");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/bar/baz');
            my $res = $cb->($req);
            is($res->content, '/BAR/BAZ', "right content for /bar/baz");
        }
    };

done_testing;
