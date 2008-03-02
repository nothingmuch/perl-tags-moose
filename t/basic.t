#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Perl::Tags::Moose';

sub tagify {
	my $code = shift;

	my $doc = PPI::Document->new( \$code );

	my $stmt = $doc->find(sub { $_[1]->isa("PPI::Statement") })->[0];

	Perl::Tags::Moose->_tagify( $stmt, "Foo.pm" );
}

{
	my @tags = tagify('has foo => ( is => "rw", clearer => "oink", handles => ["bar"], provides => { push => "la" } );');

	is ( scalar(@tags), 4, "two tags" );

	foreach my $tag ( @tags ) {
		isa_ok( $tag, "Perl::Tags::Moose::Tag::Attribute" );
	}

	my %tags = map { $_->{name} => $_ } @tags;

	is( $tags{foo}{name}, "foo",    "foo attr" );
	is( $tags{foo}{file}, "Foo.pm", "file" );

	is( $tags{bar}{name}, "bar",    "bar delegation" );
	is( $tags{bar}{file}, "Foo.pm", "file" );

	is( $tags{oink}{name}, "oink",   "oink clearer" );
	is( $tags{oink}{file}, "Foo.pm", "file" );

	is( $tags{la}{name}, "la",     "la helper" );
	is( $tags{la}{file}, "Foo.pm", "file" );
}

{
	my $tag = tagify("around 'blah' => sub { };");

	ok( $tag, "got a tag" );

	isa_ok( $tag, "Perl::Tags::Moose::Tag::Modifier" );

	is( $tag->{name}, "blah",    "blah around" );
	is( $tag->{file}, "Foo.pm", "file" );
}

{
	my @tags = tagify("with qw(\nFoo::Bar\n    Gorch\n);");

	ok( scalar(@tags), "got some tags" );

	foreach my $tag ( @tags ) {
		isa_ok( $tag, "Perl::Tags::Tag::Recurse" );
	}

	is_deeply(
		[ map { $_->{name} } @tags ],
		[ qw(Foo::Bar Gorch) ],
		"right packages",
	);
}
