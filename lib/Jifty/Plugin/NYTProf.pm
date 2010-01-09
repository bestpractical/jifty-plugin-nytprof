package Jifty::Plugin::NYTProf;
use strict;
use warnings;
use base 'Jifty::Plugin';
use File::Path 'mkpath';
use Template::Declare::Tags;

__PACKAGE__->mk_accessors(qw/is_profiling_requests/);

sub prereq_plugins { 'RequestInspector' }

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
    my $dir = File::Spec->catfile(__PACKAGE__->_static_root, '_profile' );
    mkpath [$dir] unless -d $dir;
    return $dir;
}

sub profile_dir {
    my $self = shift;
    my $id   = shift;

    return File::Spec->catfile($self->base_root, "nytprof-$id");
}

sub profile_file {
    my $self = shift;
    my $id   = shift;

    return $self->profile_dir($id) . ".out";
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
        $self->is_profiling_requests(1);
    }

    if ($self->is_profiling_requests) {
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

    return unless $self->is_profiling_requests;

    my $id = Jifty->web->serial;

    DB::enable_profile($self->profile_file($id));

    return $id;
}

sub inspect_after_request {
    my $self = shift;
    my $id   = shift;

    return unless $self->is_profiling_requests;

    DB::finish_profile();

    return $id;
}

sub inspect_render_analysis {
    my $self = shift;
    my $id   = shift;

    # need to generate the profile
    $self->generate_profile($id);

    my $profile = "/_profile/nytprof-$id/index.html" ;

    div {
        attr { class is 'lightbox', style is 'background-color: white'; };
        iframe {
            attr {
                class is 'lightbox',
                src is $profile,
                width is '100%',
                height is '400',
            };
        };
    };
}

sub generate_profile {
    my $self = shift;
    my $id   = shift;
    my $dir  = $self->profile_dir($id);

    if (!-d $dir) {
        my $input = $self->profile_file($id);
        die "Unable to find profile output file '$input'"
            unless -e $input;
        system("nytprofhtml -f $input -o $dir");
    }
}

1;
