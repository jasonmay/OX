package Counter::Over::Engineered;
use Moose;
use Bread::Board;

extends 'OX::Application';

with 'OX::Role::WithAppRoot',
     'OX::Role::RouteBuilder',
     'OX::Role::Path::Router';

sub BUILD {
    my $self = shift;

    container $self => as {

        container 'Model' => as {
            service 'Counter' => (
                class     => 'Counter::Over::Engineered::Model',
                lifecycle => 'Singleton',
            );
        };

        container 'View' => as {
            service 'TT' => (
                class        => 'Counter::Over::Engineered::View',
                dependencies => {
                    template_root => (service 'template_root' => (
                        block => sub {
                            (shift)->param('app_root')->subdir(qw[ root templates ])
                        },
                        dependencies => [ depends_on('/app_root') ]
                    ))
                }
            );
        };

        container 'Controller' => as {
            service 'Root' => (
                class        => 'Counter::Over::Engineered::Controller',
                dependencies => {
                    view  => depends_on('/View/TT'),
                    model => depends_on('/Model/Counter')
                }
            );
        };

        container $self->fetch('Router') => as {
            service 'config' => (
                block => sub {
                    +{
                        '/' => {
                            controller => 'root',
                            action     => 'index',
                        },
                        '/inc' => {
                            controller => 'root',
                            action     => 'inc',
                        },
                        '/dec' => {
                            controller => 'root',
                            action     => 'dec',
                        },
                        '/reset' => {
                            controller => 'root',
                            action     => 'reset',
                        },
                        '/set/:number' => {
                            controller => 'root',
                            action     => 'set',
                            number     => { isa => 'Int' }
                        },
                    }
                },
                dependencies => {
                    root => depends_on('/Controller/Root')
                }
            );
        };
    };
}


no Moose; no Bread::Board; 1;

__END__
