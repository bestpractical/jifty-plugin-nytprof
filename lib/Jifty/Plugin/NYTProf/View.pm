use strict;
use warnings;

package Jifty::Plugin::NYTProf::View;
use Jifty::View::Declare -base;
use Scalar::Util 'blessed';

=head1 NAME

Jifty::Plugin::NYTProf::View - Views for database queries

=head1 TEMPLATES

=cut

template '/__jifty/admin/profiles/all' => page {
    my $skip_zero = get 'skip_zero';

    h1 { "Profiles" }
    p {
        a { attr { href => "/__jifty/admin/profiles/clear" }
            "Clear profile log" }
    }
    hr {};

    my $render = new_action( class => 'NYTProfHTML',
                             moniker => 'nytprof_html' );
    h3 { "All profiles" };
    form {
    table {
        row {
            th { "ID" }
            th { "URL" }
        };

        for (@Jifty::Plugin::NYTProf::requests)
        {
            row {
                cell {
                    hyperlink( label => $_->{id},
                               onclick => { submit => { action => $render,
                                                        arguments => { id => $_->{id} } },
                                            region => 'profile_output',
                                            replace_with => '/__jifty/admin/profiles/_result',
                                            arguments => { id => $_->{id} } },
                               )
                };
                cell { $_->{url} };
            };
        }
    };
    };
    render_region( name => 'profile_output' );
};


template '/__jifty/admin/profiles/_result' => sub {
    my $id = get('id');

    my $profile = '/_profile/'.Jifty->app_class."-$$/nytprof-$id/index.html" ;
    div { { class is 'lightbox', style is 'background-color: white'; };
          hyperlink( label => 'close',
                     onclick => { replace_with => '/__jifty/empty' } );
          iframe { { class is 'lightbox', src is $profile, width is '100%', height is '400', }};
      };
};


=head1 SEE ALSO

L<Jifty::Plugin::NYTProf>, L<Jifty::Plugin::NYTProf::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

