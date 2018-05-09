requires "DateTime";
requires "HTTP::Link";
requires "LWP";
requires "Mojo::DOM58";
requires "Moose";
requires "MooseX::ClassAttribute";
requires "MooseX::Enumeration";
requires "MooseX::Types::URI";
requires "Path::Class::Dir";
requires "Try::Tiny";
requires "Types::Standard";
requires "Web::Microformats2::Parser";
requires "Scalar::Util";
requires "List::Util";
requires "URI::Escape";

on 'test' => sub {
    requires "Test::More";
    requires "Test::Exception";
    requires "Test::LWP::UserAgent";

    requires "Path::Class::Dir";
};
