requires "DateTime";
requires "HTTP::Link";
requires "List::Util";
requires "LWP";
requires "Mojo::DOM58";
requires "Moose";
requires "MooseX::ClassAttribute";
requires "MooseX::Enumeration";
requires "MooseX::Types::URI";
requires "Path::Class::Dir";
requires "Scalar::Util";
requires "Try::Tiny";
requires "Types::Standard";
requires "Web::Microformats2::Parser";

on 'test' => sub {
    requires "Test::More";
    requires "Test::Exception";
    requires "Test::LWP::UserAgent";

    requires "Path::Class::Dir";
};
