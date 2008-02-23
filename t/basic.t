#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Perl::Tags::Moose';

{
	my $tag = Perl::Tags::Moose->attribute_line( ("has foo => (") x 2, "Foo.pm" );

	ok( $tag, "got a tag" );

	isa_ok( $tag, "Perl::Tags::Moose::Tag::Attribute" );

	is( $tag->{name}, "foo",    "foo attr" );
	is( $tag->{file}, "Foo.pm", "file" );
}

{
	my $tag = Perl::Tags::Moose->modifier_line( ("around 'blah' => sub {") x 2, "Foo.pm" );

	ok( $tag, "got a tag" );

	isa_ok( $tag, "Perl::Tags::Moose::Tag::Modifier" );

	is( $tag->{name}, "blah",    "blah around" );
	is( $tag->{file}, "Foo.pm", "file" );
}
