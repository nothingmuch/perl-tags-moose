#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.010;

WriteMakefile(
	NAME         => 'Perl::Tags::Moose',
	VERSION_FROM => 'lib/Perl/Tags/Moose.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
		'Perl::Tags' => 0,
	},
);

