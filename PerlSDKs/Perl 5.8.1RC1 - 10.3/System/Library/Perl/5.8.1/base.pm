=head1 NAME

base - Establish IS-A relationship with base class at compile time

=head1 SYNOPSIS

    package Baz;
    use base qw(Foo Bar);

=head1 DESCRIPTION

Roughly similar in effect to

    BEGIN {
	require Foo;
	require Bar;
	push @ISA, qw(Foo Bar);
    }

Will also initialize the %FIELDS hash if one of the base classes has
it.  Multiple inheritance of %FIELDS is not supported.  The 'base'
pragma will croak if multiple base classes have a %FIELDS hash.  See
L<fields> for a description of this feature.

When strict 'vars' is in scope, I<base> also lets you assign to @ISA
without having to declare @ISA with the 'vars' pragma first.

If any of the base classes are not loaded yet, I<base> silently
C<require>s them (but it won't call the C<import> method).  Whether to
C<require> a base class package is determined by the absence of a global
$VERSION in the base package.  If $VERSION is not detected even after
loading it, I<base> will define $VERSION in the base package, setting it to
the string C<-1, set by base.pm>.

=head1 HISTORY

This module was introduced with Perl 5.004_04.

=head1 SEE ALSO

L<fields>

=cut

package base;

use 5.006_001;
our $VERSION = "1.03";

sub import {
    my $class = shift;
    my $fields_base;
    my $pkg = caller(0);

    foreach my $base (@_) {
	next if $pkg->isa($base);
        my $vglob;
	if ($vglob = ${"$base\::"}{VERSION} and *$vglob{SCALAR}) {
          $$vglob = "-1, set by base.pm" unless defined $$vglob;
        } else {
	    eval "require $base";
	    # Only ignore "Can't locate" errors from our eval require.
	    # Other fatal errors (syntax etc) must be reported.
	    die if $@ && $@ !~ /^Can't locate .*? at \(eval /;
	    unless (%{"$base\::"}) {
		require Carp;
		Carp::croak("Base class package \"$base\" is empty.\n",
			    "\t(Perhaps you need to 'use' the module ",
			    "which defines that package first.)");
	    }
	    ${"$base\::VERSION"} = "-1, set by base.pm" unless defined ${"$base\::VERSION"};
	}
	push @{"$pkg\::ISA"}, $base;

	# A simple test like (defined %{"$base\::FIELDS"}) will
	# sometimes produce typo warnings because it would create
	# the hash if it was not present before.
	my $fglob;
	if ($fglob = ${"$base\::"}{"FIELDS"} and *$fglob{HASH}) {
	    if ($fields_base) {
		require Carp;
		Carp::croak("Can't multiply inherit %FIELDS");
	    } else {
		$fields_base = $base;
	    }
	}
    }
    if ($fields_base) {
	require fields;
	fields::inherit($pkg, $fields_base);
    }
}

1;
