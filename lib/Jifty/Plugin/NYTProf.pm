use strict;
use warnings;

package Jifty::Plugin::NYTProf;
use base qw/Jifty::Plugin/;
use File::Path 'mkpath';
__PACKAGE__->mk_accessors(qw/profile_request/);

our @requests;

sub _static_root {
    my $self = shift;
    my $dir = Jifty::Util->absolute_path("var/profile");
    mkpath [$dir] unless -d $dir;
    return $dir;
}

sub static_root {
    my $self = shift;
    return ($self->SUPER::static_root(), $self->_static_root);
}

sub base_root {
    my $dir = File::Spec->catfile(__PACKAGE__->_static_root, '_profile', Jifty->app_class.'-'.$$ );
    mkpath [$dir] unless -d $dir;
    return $dir;
}

sub init {
    my $self = shift;

    unless (%DB::sub) {
        warn "Perl is not running in debug mode -- profiler disabled\n"
            . "Run as `perl -d:NYTProf ./bin/jifty server` to profile startup\n"
            . " or as `NYTPROF=start=no perl -d:NYTProf ./bin/jifty server` to profile runtime\n";
        return;
    }

    return if $self->_pre_init;

    my %args = (split /[:=]/, $ENV{NYTPROF} || '');
    if ($args{start} and $args{start} eq "no") {
        $self->profile_request(1);
    }

    if ($self->profile_request) {
        warn "Only profiling requests; unset NYTPROF environment variable to profile startup\n";

        Jifty::Handler->add_trigger(
            before_request => sub { $self->before_request(@_) }
        );

        Jifty::Handler->add_trigger(
            after_request => sub { $self->after_request(@_) }
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

    my $file = File::Spec->catfile( __PACKAGE__->base_root, 'nytprof-'.(1+scalar @requests).".out" );
    warn "==> enabling profile at $file";
    DB::enable_profile( $file );
}

sub after_request {
    my $self = shift;
    my $handler = shift;
    my $cgi = shift;
    DB::finish_profile();

    push @requests, {
        id => 1 + @requests,
        url => $cgi->url(-absolute=>1,-path_info=>1),
        time => scalar gmtime,
    };
    return 1;
}

sub clear_profiles {
    @requests = ();
}

1;
