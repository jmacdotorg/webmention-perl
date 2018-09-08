use warnings;
use strict;
use Test::More;
use Path::Class;
use FindBin;

use_ok ("Web::Mention");

my $source_path = "$FindBin::Bin/sources/many_types.html";

my $source_url = "file://$source_path";

my %type_urls;
my @types = qw(mention reply like repost quotation);

foreach ( @types ) {
    $type_urls{$_} = target_url_for_type( $_ );
}

my $html = Path::Class::File->new( $source_path )->slurp;


my @wms = Web::Mention->new_from_html(
    source => $source_url,
    html => $html,
);

for my $type ( @types ) {
    my @type_wms = grep { $_->type eq $type } @wms;
    is (scalar @type_wms, 1, "Found exactly one '$type' webmention.");
    is ($type_wms[0]->target, target_url_for_type( $type ), "That webmention has the expected target URL.");
}

sub target_url_for_type {
    my ( $type ) = @_;

    return "http://example.com/$type-target";
}

done_testing();
