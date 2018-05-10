# NAME

Web::Mention - Implementation of the IndieWeb Webmention protocol

# SYNOPSIS

    use Web::Mention;
    use Try::Tiny;
    use v5.10;

    # Building a webmention from an incoming web request:

    my $wm;
    try {
        # $request can be any object that provides a 'param' method, such as
        # Catalyst::Request or Mojo::Message::Request.
        $wm = Web::Mention->new_from_request ( $request )
    }
    catch {
        say "Oops, this wasn't a webmention at all: $_";
    };

    if ( $wm && $wm->is_verified ) {
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
       say "This webmention doesn't actually mention its target URL, "
           . "so it is not verified.";
    }

    # Manually buidling and sending a webmention:

    $wm = Web::Mention->new(
       source => $url_of_the_thing_that_got_mentioned,
       target => $url_of_the_thing_that_did_the_mentioning
    );

    my $success = $wm->send;
    if ( $success ) {
        say "Webmention sent successfully!";
    }
    else {
        say "The webmention wasn't sent successfully.";
        say "Here's the response we got back..."
        say $wm->response;
    }
    

# DESCRIPTION

This class implements the Webmention protocol, as defined by the W3C and
the IndieWeb community. (See: [https://indieweb.org/Webmention](https://indieweb.org/Webmention))

An object of this class represents a single webmention, with target and
source URLs. It can verify itself, determining whether or not the
document found at the source URL does indeed mention the target URL. It
can also use the Indieweb authorship algorithm to identify and describe
the author of source document, if possible.

# NOTES AND BUGS

This software is **alpha**; its author is still determining how it wants
to work, and its interface might change dramatically.

Implementation of the content-fetching method is incomplete.

# SUPPORT

To file issues or submit pull requests, please see [this module's
repository on GitHub](https://github.com/jmacdotorg/webmention-perl).

The author also welcomes any direct questions about this module via email.

# AUTHOR

Jason McIntosh (jmac@jmac.org)

# CONTRIBUTORS

- Mohammad S Anwar (mohammad.anwar@yahoo.com)

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jason McIntosh.

This is free software, licensed under:

    The MIT (X11) License
