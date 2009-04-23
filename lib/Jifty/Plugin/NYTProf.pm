package Jifty::Plugin::NYTProf;
use strict;
use warnings;
use base 'Jifty::Plugin';
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
    } else {
        warn "Only profiling startup time -- set NYTPROF=start=no to profile requests\n";
        Jifty->add_trigger(
            post_init => sub { DB::disable_profile() }
        );
    }
}

sub inspect_before_request {
    my $self = shift;

    return unless $self->profile_request;

    my $id = Jifty->web->serial;

    my $file = File::Spec->catfile( __PACKAGE__->base_root, "nytprof-$id" );
    warn "==> enabling profile at $file.out";

    DB::enable_profile("$file.out");

    return $file;
}

sub inspect_after_request {
    my $self = shift;
    my $file = shift;

    return unless $self->profile_request;

    DB::finish_profile();

    return $file;
}

sub inspect_render_analysis {
    my $self = shift;
    my $file = shift;

    my ($self_plugin) = Jifty->find_plugin('Jifty::Plugin::NYTProf');
    return if -d "$file";
    die "Unable to find profile output file '$file.out'" unless -e "$file.out";
    system("nytprofhtml -f $file.out -o $file");

    return;
}

1;
