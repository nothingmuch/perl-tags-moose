package Perl::Tags::Moose;

use 5.010;

our $VERSION = "0.01";

use Perl::Tags ();
use Perl::Tags::Moose::Tag::Attribute ();
use Perl::Tags::Moose::Tag::Modifier ();

use base qw(Perl::Tags::Naive);

# TODO

# find a way to support with and extends, not really possible for with
# qw(\n...\n); etc, because of Perl::Tags' current design

# try to parse 'Foo->meta' as a complete tag in VIM and emit such a tag by
# keeping track of the current package and jumping to the use metaclass line?

my $sugar_identifier = qr/
	\s* \(? \s*         # parens are allowed, e.g. has( ... ) or add_attribute( ... )
	(?: ['"] | qq?. )?  # ditch quotes

	(?<ident> \w+ )     # the identifier itself
/x;

my $match_attr = qr/
	(?:add_attribute|has)
	$sugar_identifier
/x;

my $match_modifier = qr/
	(?:
		override | augment | around | before | after
		add_method_modifier |
		event # MooseX::POE
	)

	$sugar_identifier
/x;

my $match_compose = qr(
	(?: extends | with )
);

sub get_parsers {
	my $self = shift;

	return (
		$self->can('attribute_line'),
		$self->can('modifier_line'),
		$self->SUPER::get_parsers(),
	);
}

sub _parse_line {
	my ( $self, $re, $class, $line, $statement, $file, @args ) = @_;

	return unless defined $statement;

	$class = "Perl::Tags::Moose::Tag::$class" unless $class =~ /::/;

	if ( $statement =~ $re ) {
		return $class->new(
			( defined($+{ident}) ? ( name => $+{ident} ) : () ),
			file => $file,
			line => $line,
			linenum => $.,
			@args,
		);
	}

	return;
}

sub attribute_line {
	my ( $self, @args ) = @_;
	$self->_parse_line( $match_attr, "Attribute", @args );
}

sub modifier_line {
	my ( $self, @args ) = @_;
	$self->_parse_line( $match_modifier, "Modifier", @args );
}

__PACKAGE__

__END__

=pod

=head1 NAME

Perl::Tags::Moose - Primitive Moose support for L<Perl::Tags>.

=head1 SYNOPSIS

	# in your perl.vim or whatever

	Perl::Tags::Moose->new( ... );

	# instead of

	Perl::Tags::Naive->new( ... );

=head1 DESCRIPTION

This module extends L<Perl::Tags> to provide very simplistic attribute and
method modifier support for Moose source code.

The heuristics are stupid, so beware that they will not always work.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
