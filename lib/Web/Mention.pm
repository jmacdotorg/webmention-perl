package Web::Mention;

use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::URI qw(Uri);
use LWP;
use DateTime;
use Try::Tiny;
use Types::Standard qw(Enum);
use MooseX::Enumeration;
use Scalar::Util;
use Carp qw(croak);

use Web::Microformats2::Parser;
use Web::Mention::Author;

has 'source' => (
    isa => Uri,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has 'original_source' => (
    isa => Uri,
    is => 'ro',
    lazy_build => 1,
    coerce => 1,
);

has 'source_html' => (
    isa => 'Maybe[Str]',
    is => 'rw',
);

has 'source_mf2_document' => (
    isa => 'Maybe[Web::Microformats2::Document]',
    is => 'rw',
    lazy_build => 1,
);

has 'target' => (
    isa => Uri,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has 'is_verified' => (
    isa => 'Bool',
    is => 'ro',
    lazy_build => 1,
);

has 'time_verified' => (
    isa => 'DateTime',
    is => 'rw',
);

has 'time_received' => (
    isa => 'DateTime',
    is => 'ro',
    default => sub{ DateTime->now },
);

has 'author' => (
    isa => 'Maybe[Web::Mention::Author]',
    is => 'ro',
    lazy_build => 1,
);

has 'type' => (
    isa => Enum[qw(reply like repost quotation mention)],
    traits => ['Enumeration'],
    handles => [qw(is_reply is_like is_repost is_quotation is_mention)],
    is => 'ro',
    lazy_build => 1,
);

has 'content' => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy_build => 1,
);

class_has 'ua' => (
    isa => 'LWP::UserAgent',
    is => 'ro',
    default => sub { LWP::UserAgent->new },
);

sub _build_is_verified {
    my $self = shift;

    return $self->verify;
}

sub new_from_request {
    my $class = shift;

    my ( $request ) = @_;

    unless ( blessed($request) && $request->can('param') ) {
        croak 'The argument to new_from_request must be an object that '
              . "supports a param() method. (Got: $request)\n";
    }

    my @complaints;
    my %new_args;
    foreach ( qw(source target) ) {
        if ( my $value = $request->param( $_ ) ) {
            $new_args{ $_ } = $value;
        }

        unless ( defined $new_args{ $_ } ) {
            push @complaints, "No param value set for $_.";
        }
    }

    if ( @complaints ) {
        croak join q{ }, @complaints;
    }

    return $class->new( %new_args );
}

sub verify {
    my $self = shift;

    my $response = $self->ua->get( $self->source );

    if ($response->content =~ $self->target ) {
        $self->time_verified( DateTime->now );
        $self->source_html( $response->content );
        return 1;
    }
    else {
        return 0;
    }
}

sub _build_source_mf2_document {
    my $self = shift;

    return unless $self->is_verified;
    my $doc;
    try {
        my $parser = Web::Microformats2::Parser->new;
        $doc = $parser->parse( $self->source_html );
    }
    catch {
        die "Error parsing source HTML: $_";
    };
    return $doc;
}

sub _build_author {
    my $self = shift;

    return Web::Mention::Author->new_from_mf2_document(
        $self->source_mf2_document
    );
}

sub _build_type {
    my $self = shift;

    my $item = $self->source_mf2_document->get_first( 'h-entry' );
    return 'mention' unless $item;

    if ( $item->get_property( 'in-reply-to' ) ) {
        return 'reply';
    }
    elsif ( $item->get_property( 'like-of' ) ) {
        return 'like';
    }
    elsif ( $item->get_property( 'repost-of' )) {
        return 'repost';
    }
    elsif ( $item->get_property( 'quotation-of' )) {
        return 'quotation';
    }
    else {
        return 'mention';
    }
}

sub _build_content {
    my $self = shift;
    # XXX This is inflexible and not on-spec

    my $item = $self->source_mf2_document->get_first( 'h-entry' );
    if ( $item->get_property( 'content' ) ) {
        return $item->get_property( 'content' )->{value};
    }
    else {
        return;
    }
}

sub _build_original_source {
    my $self = shift;

    if ( my $item = $self->source_mf2_document->get_first( 'h-entry' ) ) {
        if ( my $url = $item->get_property( 'url' ) ) {
            return $url;
        }
    }

    return $self->source;
}


# Called by the JSON module during JSON encoding.
# Contrary to the (required) name, returns an unblessed reference, not JSON.
# See https://metacpan.org/pod/JSON#OBJECT-SERIALISATION
sub TO_JSON {
    my $self = shift;

    return {
        source => $self->source->as_string,
        target => $self->target->as_string,
        is_verified => $self->is_verified,
        time_received => $self->time_received->epoch,
        time_verified => $self->time_verified->epoch,
        type => $self->type,
        mf2_document_json =>
            $self->source_mf2_document
            ? $self->source_mf2_document->as_json
            : undef,
    };
}

# Class method to construct a Webmention object from an unblessed reference,
# as created from the TO_JSON method. All-caps-named for the sake of parity.
sub FROM_JSON {
    my $class = shift;
    my ( $data_ref ) = @_;

    foreach ( qw( time_received time_verified ) ) {
        $data_ref->{ $_ } = DateTime->from_epoch( epoch => $data_ref->{ $_ } );
    }

    my $webmention = $class->new( $data_ref );

    if ( my $mf2_json = $data_ref->{ mf2_document_json } ) {
        my $doc = Web::Microformats2::Document->new_from_json( $mf2_json );
        $webmention->source_mf2_document( $doc );
    }

    return $webmention;
}

1;

=pod

=head1 NAME

Web::Mention - Implementation of the IndieWeb Webmention protocol

=head1 SYNOPSIS

 use Web::Mention;
 use Try::Tiny;
 use v5.22;

 # Define a simple handler that, given a web-request object, determines
 # whether it contains a webmention, and reacts to it if so.
 sub find_webmention ( $request ) {

    # $request is an object that provides a 'param' method, such as
    # Catalyst::Request or Mojo::Message::Request.

    my $wm;
    try {
        $wm = Web::Mention->new_from_request ( $request )
    }
    catch {
        say "Oops, this wasn't a webmention at all: $_";
    };
    return unless $wm;

    if ( $wm->is_verified ) {
        my $author = $wm->author;
        my $name;
        if ( $author ) {
            $name = $author->name;
        }
        else {
            $name = 'somebody';
        }

        my $source = $wm->original_source;
        my $target = $wm->target;

        if ( $wm->is_like ) {
            say "Hooray, $name likes $target!";
        }
        elsif ( $wm->is_repost ) {
            say "Gadzooks, over at $source, $name reposted $target!";
        }
        elsif ( $wm->is_reply ) {
            say "Hmm, over at $source, $name said this about $target:";
            say $wm->content;
        }
        else {
            say "I'll be darned, $name mentioned $target at $source!";
        }
    }
    else {
       say "What the heck, this so-called 'webmention' doesn't actually "
             . "mention its target URL. The nerve!";
    }
 }

 # Manually buidling a webmention:

 my $wm = Web::Mention->new(
    source => $url_of_the_thing_that_got_mentioned,
    target => $url_of_the_thing_that_did_the_mentioning
 );

 # Sending a webmention:
 # ...watch this space.

=head1 DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See: L<https://indieweb.org/Webmention>)

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL. It
can also use the Indieweb authorship algorithm to identify and describe
the author of source document, if possible.

=head1 METHODS

=head2 Class Methods

=over

=item new ( source => $source_url, target => $target_url )

Basic constructor. The B<source> and B<target> URLs are both required
arguments. Either one can either be a L<URI> object, or a valid URL
string.

Per the Webmention protocol, the B<source> URL represents the location
of the document that made the mention described here, and B<target>
describes the location of the document that got mentioned.

=item new_from_request( $request_object )

Convenience constructor that looks into the given web-request object for
B<source> and B<target> parameters, and attempts to build a new
Web::Mention object out of them.

The object must provide a C<param( $param_name )> method that returns the
value of the named HTTP parameter. So it could be a L<Catalyst::Request>
object or a L<Mojo::Message::Request> object, for example.

Throws an exception if the given argument doesn't meet this requirement,
or if it does but does not define both required HTTP parameters.

=back

=head2 Object Methods

=over

=item source ( )

Returns the webmention's source URL, as a L<URI> object.

=item target ( )

Returns the webmention's target URL, as a L<URI> object.

=item is_verified ( )

Returns 1 if the webmention's source document actually does seem to
mention the target URL. Otherwise returns 0.

The first time this is called on a given webmention object, it will try
to fetch the source document at its designated URL. If it cannot fetch
the document on this first attempt, this method returns 0.

=item type ( )

The type of webmention this is. One of:

=over

=item *

mention I<(default)>

=item *

reply

=item *

like

=item *

repost

=item *

quotation

=back

=item author ( )

A Web::Mention::Author object representing the author of this
webmention's source document, if we're able to determine it. If not,
this returns undef.

=item source_html ( )

The HTML of the document fetched from the source URL. If nothing got
fetched successfully, returns undef.

=item source_mf2_document ( )

The Web::Microformats2::Document object that resulted from parsing the
source document for Microformats2 metadata. If no such result, returns
undef.

=item content ( )

The content of this webmention, if its source document exists and
defines its content using Microformats2. If not, this returns undef.

=item original_source ( )

If the document fetched from the source URL seems to point at yet
another URL as its original source, then this returns that URL. If not,
this has the same return value as C<source()>.

(It makes this determination based on the possible presence a C<u-url>
property in an C<h-entry> found within the source document.)

=back

=head1 NOTES AND BUGS

Implementation of the content-fetching method is incomplete.

This software is B<alpha>; its author is still determining how it wants
to work, and its interface might change dramatically.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

