# Web::Mention

This set of Perl 5 classes implements the Webmention protocol, as defined by the W3C and the IndieWeb community. For more on Webmention, please see [https://indieweb.org/Webmention](https://indieweb.org/Webmention).

These libraries are too green for proper system installers, let alone CPAN. So, for full documentation, run `perldoc` on lib/Web/Mention.pm and lib/Web/Mention/Author.pm. (Or just view their source and scroll to the bottom.)

Everything here is super-duper alpha, as of mid-April 2018. The author is just starting to dogfood this stuff on an experimental branch of his own website. Anything could change.

# Synopsis

```
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

```

# Prerequisites

You'll need <a href="https://github.com/jmacdotorg/microformats2-perl">Web::Microformats2</a>, which isn't on CPAN yet, and is at least as half-baked as this module. At most as half-baked. One of those.

# Author

Jason McIntosh (jmac@jmac.org)

# Other contributors

The tests in `t/authorship-test-cases` are based on work by Sandeep Shetty, originally found at https://github.com/sandeepshetty/authorship-test-cases.