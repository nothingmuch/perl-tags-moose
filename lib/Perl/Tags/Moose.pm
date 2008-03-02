package Perl::Tags::Moose;

use 5.010;

our $VERSION = "0.01";

use Perl::Tags::PPI ();
use Perl::Tags::Moose::Tag::Attribute ();
use Perl::Tags::Moose::Tag::Modifier ();

use Safe;

use base qw(Perl::Tags::PPI);

my $safe = Safe->new;

$safe->share_from( "Perl::Tags::Moose::Sugar", [ map { '&' . $_ } keys %Perl::Tags::Moose::Sugar:: ] );


sub _tagify {
	my ( $self, @args ) = @_;
	my ( $thing, $file ) = @args;

	if ( $thing->class eq 'PPI::Statement' ) {
		if ( my $first = $thing->first_element ) {
			if ( $first->class eq 'PPI::Token::Word' ) { # FIXME array refs of constants should also be supported
				my $sugar = $first->literal;

				if ( Perl::Tags::Moose::Sugar->can($sugar) ) {
					return $self->_tagify_moose_sugar($sugar, $thing, $file);
				}
			}
		}
	}

	$self->SUPER::_tagify(@args);
}

sub _tagify_moose_sugar {
	my ( $self, $sugar, $ppi, $file ) = @_;

	my $str = "$ppi";

	my @attrs = $safe->reval($str);

	unless ( $@ ) {
		my $line = split /\n/, $str;

		return $self->_construct_moose_tag(
			type      => $sugar,
			statement => $ppi,
			file      => $file,
			line      => $line,
			linenum   => $ppi->location->[0],
			params    => \@attrs,
		);
	} else {
		warn $@;
		return;
	}
}

sub _construct_moose_tag {
	my ( $self, %args ) = @_;

	my $method = "_construct_moose_tag_$args{type}";

	$self->$method( %args );
}

sub _construct_moose_tag_has {
	my ( $self, %args ) = @_;

	my %params = ( name => @{ $args{params} } );

	my %seen;
	my @names = grep { defined and not ref and not $seen{$_}++ } (
		$self->_extract_accessor_methods(%params),
		$self->_extract_delegation_methods(%params),
		$self->_extract_attribute_helper_methods(%params),
	);

	map {
		Perl::Tags::Moose::Tag::Attribute->new(
			%params,
			%args,
			name => $_,
		);
	} @names;
}

sub _extract_accessor_methods {
	my ( $self, %params ) = @_;

	no warnings 'uninitialized';

	my %accessors = (
		( $params{is} eq 'rw' ? ( setter => $params{name}, getter => $params{name} ) : () ),
		( $params{is} eq 'ro' ? ( getter => $params{name} ) : () ),
		( $params{is} eq 'wo' ? ( setter => $params{name} ) : () ),
		( exists $params{getter} ? ( getter => $params{getter} ) : () ),
		( exists $params{setter} ? ( setter => $params{setter} ) : () ),
		( exists $params{predicate} ? ( predicate => $params{predicate} ) : () ),
		( exists $params{clearer}   ? ( clearer   => $params{clearer} ) : () ),
	);

	return values %accessors;
}

sub _extract_delegation_methods {
	my ( $self, %params ) = @_;

	if ( my $ref = ref($params{handles}) ) {
		my $method = "_extract_delegation_methods_" . lc($ref);

		return unless $self->can($method);

		return $self->$method(%params);
	}

	return;
}

sub _extract_delegation_methods_array {
	my ( $self, %params ) = @_;

	return @{ $params{handles} };
}

sub _extract_delegation_methods_hash {
	my ( $self, %params ) = @_;

	return values %{ $params{handles} };
}

sub _extract_attribute_helper_methods {
	my ( $self, %params ) = @_;

	if ( ( ref(my $provides = $params{provides}) || '' ) eq 'HASH' ) {
		return values %$provides,
	}

	return;
}

sub _construct_moose_tag_modifier {
	my ( $self, %args ) = @_;

	my @params = ( name => $args{params}[0] );

	Perl::Tags::Moose::Tag::Modifier->new(
		@params,
		%args,
	);
}

sub _construct_moose_tag_around   { shift->_construct_moose_tag_modifier(@_) }
sub _construct_moose_tag_before   { shift->_construct_moose_tag_modifier(@_) }
sub _construct_moose_tag_after    { shift->_construct_moose_tag_modifier(@_) }
sub _construct_moose_tag_override { shift->_construct_moose_tag_modifier(@_) }
sub _construct_moose_tag_augment  { shift->_construct_moose_tag_modifier(@_) }
sub _construct_moose_tag_event    { shift->_construct_moose_tag_modifier(@_) } # not really a modifier, but hey, it works

sub _construct_moose_tag_recurse {
	my ( $self, %args ) = @_;

	map {
		Perl::Tags::Tag::Recurse->new(
			name => $_, 
			line=>'dummy'
		);
	} @{ $args{params} },
}

sub _construct_moose_tag_with { shift->_construct_moose_tag_recurse(@_) }
sub _construct_moose_tag_extends { shift->_construct_moose_tag_recurse(@_) }

{
	package Perl::Tags::Moose::Sugar;

	sub extends (@) { @_ }

	sub with (@) { @_ }

	sub has ($;%) { @_ }

	sub around (@&) { @_ }

	sub before (@&) { @_ }

	sub after (@&) { @_ }

	sub override (@&) { @_ }

	sub augment (@&) { @_ }
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

This module extends L<Perl::Tags::PPI> to provide very simplistic attribute and
method modifier support for Moose source code.

It will also produce L<Perl::Tags::Tag::Recurse> tags for C<extends> and
C<with> declarations.

The heuristics are stupid, so beware that they will not always work, for
instance if the expressions for the sugar rely on complex expressions or
variables.

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
