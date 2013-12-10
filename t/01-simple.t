use strict;
use warnings;

use Plack::Builder;
use Plack::Runner;
use Plack::App::Directory;
use Test::Mocha::PhantomJS;

BEGIN {
    system "which mocha-phantomjs > /dev/null";
    if ($? != 0) {
        require "Test/More.pm";
        Test::More::plan(skip_all => "could not find mocha-phantomjs");
    }
}

test_mocha_phantomjs(
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options("--port", $port);
        my $app = builder {
            enable "DirIndex", dir_index => "index.html";
            Plack::App::Directory->new(root => "t/01-simple")->to_app;
        };
        $runner->run($app);
    },
);
