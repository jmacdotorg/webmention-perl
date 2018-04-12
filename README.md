# Web::Mention

This set of Perl 5 classes implements the Webmention protocol, as defined by the W3C and the IndieWeb community. For more on Webmention, please see [https://indieweb.org/Webmention](https://indieweb.org/Webmention).

These libraries are too green for proper system installers, let alone CPAN. So, for full documentation, run `perldoc` on lib/Web/Mention.pm and lib/Web/Mention/Author.pm. (Or just view their source and scroll to the bottom.)

Everything here is super-duper alpha, as of mid-April 2018. The author is just starting to dogfood this stuff on an experimental branch of his own website. Anything could change.

# Synopsis

```
 use Web::Mention;

 # Verifying a received webmention, and working with its source content.
 my $wm = Web::Mention->new(
    source => $url_of_something_that_mentioned_a_url_of_mine,
    target => $url_that_got_mentioned,
 );

 if ( $wm->is_verified ) {
    my $author = $wm->author;
    my $name;
    if ( $author ) {
        $name = $author->name;
    }
    else {
        $name = 'somebody';
    }

    my $source = $wm->source;
    my $target = $wm->target;

    if ( $wm->type eq 'like' ) {
        say "Hooray, $name likes $target!";
    }
    elsif ( $wm->type eq 'repost' ) {
        say "Gadzooks, over at $source, $name reposted $target!";
    }
    elsif ( $wm->type eq 'reply' ) {
        say "Hmm, over at $source, $name said this about $target:";
        say $wm->content;
    }
    else {
        say "I'll be darned, $name mentioned $target at $source!";
    }
 }
 else {
    say "What the heck, this so-called 'webmention' doesn't actually "
          . "mention its target URL. The nerve!\n";
 }

 # Sending a webmention:
 # ...watch this space.

```

# Prerequisites

You'll need <a href="https://github.com/jmacdotorg/microformats2-perl">Web::Microformats2</a>, which isn't on CPAN yet, and is at least as half-baked as this module. At most as half-baked. One of those.

# Author

Jason McIntosh (jmac@jmac.org)

# Other contributors

The tests in `t/authorship-test-cases` are based on work by Sandeep Shetty, originally found at https://github.com/sandeepshetty/authorship-test-cases.