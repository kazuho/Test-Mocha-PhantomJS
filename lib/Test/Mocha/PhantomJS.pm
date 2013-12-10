package Test::Mocha::PhantomJS;

use strict;
use warnings;

use Exporter qw(import);
use Net::EmptyPort qw(empty_port wait_port);
use Scope::Guard qw(scope_guard);

our $VERSION = '0.01';
our @EXPORT = qw(test_mocha_phantomjs);
our @EXPORT_OK = @EXPORT;

sub test_mocha_phantomjs {
    my %args = @_ == 1 ? %{$_[0]} : @_;
    Carp::croak("missing mandatory parameter 'server'")
        unless exists $args{server};
    %args = (
        max_wait  => 10,
        build_uri => sub {
            my $port = shift;
            "http://127.0.0.1:$port/";
        },
        %args,
    );

    my $client_pid = $$;

    # determine empty port
    my $port = empty_port();

    # start server
    my $server_pid = fork;
    die "fork failed:$!"
        unless defined $server_pid;
    if ($server_pid == 0) {
        eval {
            $args{server}->($port);
        };
        # should not reach here
        warn $@;
        die "[Test::Mocha::PhantomJS] server callback should not return";
    }

    # setup guard to kill the server
    my $guard = scope_guard sub {
        kill 'TERM', $server_pid;
        waitpid $server_pid, 0;
        print STDERR "hi";
    };

    # wait for the port to start
    wait_port($port, $args{max_wait});

    # run the test
    system qw(mocha-phantomjs -R tap), $args{build_uri}->($port);
    my $status = $?;

    undef $guard; # stop the server

    if ($status == 1) {
        die "failed to execute mocha-phantomjs: $status";
    } elsif (($status & 127) != 0) {
        die "mocha-phantomjs died with signal " . ($status & 127);
    } else {
        warn "mocha-phantomjs exitted with: $status";
        exit $status >> 8;
    }
}

1;
__END__

=head1 NAME

Test::Mocha::PhantomJS - a wrapper for mocha-phantomjs

=head1 SYNOPSIS

  use Test::Mocha::PhantomJS;

  test_mocha_phantomjs(
      server => sub {
          my $port = shift;
          # start server at $port that returns the test code
          # for mocha-phantomjs
          ...
      },
  );

=head1 AUTHOR

Kazuho Oku

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
