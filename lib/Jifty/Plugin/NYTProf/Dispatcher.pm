package Jifty::Plugin::NYTProf::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

# http://your.app/queries -- display full profile report
on '/__jifty/admin/profiles' => run {
    set 'skip_zero' => 1;
    show "/__jifty/admin/profiles/all";
};

# http://your.app/profiles/all -- full profile report with non-query requests
on '/__jifty/admin/profiles/all' => run {
    set 'skip_zero' => 0;
    show "/__jifty/admin/profiles/all";
};

# http://your.app/profiles/clear -- clear profile results
on '/__jifty/admin/profiles/clear' => run {
    Jifty::Plugin::NYTProf->clear_profiles;
    set 'skip_zero' => 1;
    redirect "/__jifty/admin/profiles";
};

=head1 NAME

Jifty::Plugin::NYTProf::Dispatcher - Dispatcher for NYTProf plugin

=head1 SEE ALSO

L<Jifty::Plugin::NYTProf>, L<Jifty::Plugin::NYTProf::View>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

