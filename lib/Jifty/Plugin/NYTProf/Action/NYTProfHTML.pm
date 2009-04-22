package Jifty::Plugin::NYTProf::Action::NYTProfHTML;
use strict;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'id';
};

sub take_action {
    my ($self) = @_;
    my ($self_plugin) = Jifty->find_plugin('Jifty::Plugin::NYTProf');
    my $file = $self_plugin->base_root."/nytprof-".$self->argument_value('id');
    return if -d "$file";
    die unless -e "$file.out";
    system("nytprofhtml -f $file.out -o $file");
    # XXX: error reporting etc
    return;
}

1;
