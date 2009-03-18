use strict;
use warnings;

package Jifty::Plugin::NYTProf;
use base qw/Jifty::Plugin/;
__PACKAGE__->mk_accessors(qw/first_request path/);

sub init {
    my $self = shift;

    unless (%DB::sub) {
        warn "Perl is not running in debug mode -- profiler disabled\n"
            . "Run as `perl -d:NYTProf ./bin/jifty server` to profile startup\n"
            . " or as `NYTPROF=start=no perl -d:NYTProf ./bin/jifty server` to profile runtime\n";
        return;
    }

    my %args = (split /[:=]/, $ENV{NYTPROF} || '');
    if ($args{start} and $args{start} eq "no") {
        warn "Only profiling requests; unset NYTPROF environment variable to profile startup\n";
        $self->path(Jifty::Util->absolute_path("var/profile"));
        unless (-e $self->path or mkdir $self->path) {
            warn "Can't create @{[$self->path]} for profiling: $!";
            return;
        }

        $self->first_request(1);

        Jifty::Handler->add_trigger(
            before_request => sub { $self->before_request(@_) }
        );

        Jifty::Handler->add_trigger(
            before_cleanup => sub { $self->before_cleanup }
        );
    } else {
        warn "Only profiling startup time -- set NYTPROF=start=no to profile requests\n";
        Jifty->add_trigger(
            post_init => sub { DB::disable_profile() }
        );
    }
}

sub before_request {
    my $self = shift;
    return if $self->first_request;

    DB::enable_profile($self->path . "/nytprof.$$.out")
}

sub before_cleanup {
    my $self = shift;
    DB::disable_profile()
          unless $self->first_request;

    $self->first_request(0);
}

1;
