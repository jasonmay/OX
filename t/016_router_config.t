#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

{
    package Foo::Root;
    use Moose;

    sub index { 'FOO ROOT INDEX' }
}

{
    package Foo;
    use Moose;
    use Bread::Board;

    extends 'OX::Application';
    with 'OX::Role::RouteBuilder', 'OX::Role::Path::Router';

    sub BUILD {
        my $self = shift;

        container $self => as {
            service root => (
                class => 'Foo::Root',
            );

            container $self->fetch('Router') => as {
                service 'config' => (
                    block => sub {
                        +{
                            '/' => {
                                controller => 'root',
                                action     => 'index',
                            },
                            '/foo' => sub { 'FOO' },
                        }
                    },
                    dependencies => {
                        root => depends_on('../root')
                    }
                );
            };
        };
    }
}

test_psgi
    app    => Foo->new->to_app,
    client => sub {
        my $cb = shift;
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/');
            my $res = $cb->($req);
            is($res->content, 'FOO ROOT INDEX', "right content");
        }
        {
            my $req = HTTP::Request->new(GET => 'http://localhost/foo');
            my $res = $cb->($req);
            is($res->content, 'FOO', "right content");
        }
    };

done_testing;
