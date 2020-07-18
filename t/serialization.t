use warnings; use strict;
use Test::More;
use Test::LWP::UserAgent;
use Test::Warn;
use FindBin;
use JSON;

use_ok ("Web::Mention");
my $source = 'file://' . "$FindBin::Bin/sources/content_property.html";
my $target = "http://example.com/webmention-target";

# Test serialization using JSON methods manually
{
my $wm = Web::Mention->new(
    source => $source,
    target => $target,
);
ok (not($wm->is_tested), "Webmention marked as untested.");
ok ($wm->is_verified, "Webmention got verified.");
ok ($wm->is_tested, "Webmention marked as tested.");

my $json = JSON->new->convert_blessed;

my $serialized_wm = $json->encode($wm);

my $unserialized_wm = Web::Mention->FROM_JSON( $json->decode($serialized_wm) );

is ($unserialized_wm->source, $source,
    'Manually unserialized webmention remembers its source.',
);

ok ($unserialized_wm->is_tested,
    'Manually unserialized webmention remembers its is_tested status.',
);
}

# Test serialization using the library's own JSON methods
{
my $wm = Web::Mention->new(
    source => $source,
    target => $target,
);
my $serialized_wm = $wm->as_json;
my $unserialized_wm = Web::Mention->new_from_json( $serialized_wm );

is ($unserialized_wm->source, $source,
    'Unserialized, untested webmention remembers its source.',
);
ok (not($unserialized_wm->is_tested),
    'Unserialized, untested webmention remembers its is_tested status.',
);

$wm->verify;

$serialized_wm = $wm->as_json;
$unserialized_wm = Web::Mention->new_from_json( $serialized_wm );

is ($unserialized_wm->source, $source,
    'Unserialized, verified webmention remembers its source.',
);

ok ($unserialized_wm->is_tested,
    'Unserialized, verified webmention remembers its is_tested status.',
);

}

done_testing();
