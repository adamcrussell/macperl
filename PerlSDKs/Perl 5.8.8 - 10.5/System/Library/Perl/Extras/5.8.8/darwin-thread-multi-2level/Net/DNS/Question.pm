package Net::DNS::Question;
#
# $Id: Question.pm 659 2007-06-21 14:26:19Z olaf $
#
use strict;
BEGIN { 
    eval { require bytes; }
} 

use vars qw($VERSION $AUTOLOAD);

use Carp;
use Net::DNS;

$VERSION = (qw$LastChangedRevision: 659 $)[1];

=head1 NAME

Net::DNS::Question - DNS question class

=head1 SYNOPSIS

C<use Net::DNS::Question>

=head1 DESCRIPTION

A C<Net::DNS::Question> object represents a record in the
question section of a DNS packet.

=head1 METHODS

=head2 new

    $question = Net::DNS::Question->new("example.com", "MX", "IN");

Creates a question object from the domain, type, and class passed
as arguments.

RFC4291 and RFC4632 IP address/prefix notation is supported for
queries in in-addr.arpa and ip6.arpa subdomains.

=cut

sub new {
	my $class = shift;

	my $qname = defined ($_ = shift) ? $_ : '';
	my $qtype = uc shift || 'A';
	my $qclass = uc shift || 'IN';

	$qname =~ s/\.+$//o;	# strip gratuitous trailing dot

 	# Check if the caller has the type and class reversed.
 	# We are not that kind for unknown types.... :-)
	($qtype, $qclass) = ($qclass, $qtype)
		if exists $Net::DNS::classesbyname{$qtype}
		and exists $Net::DNS::typesbyname{$qclass};

	# if argument is an IP address, do appropriate reverse lookup
	if ( $qname =~ m/\d$|[:\/]/o ) {
		my $type = $qtype =~ m/^(A|AAAA)$/o ? 'PTR' : $qtype;
		($qname, $qtype) = ($_, $type) if $_ = dns_addr($qname);
	}

	my $self = {	qname	=> $qname,
			qtype	=> $qtype,
			qclass	=> $qclass
			};

	bless $self, $class;
}


sub dns_addr {
	my $arg = shift;	# name or IP address

	# If arg looks like IP4 address then map to in-addr.arpa space
	if ( $arg =~ /((^|\d+\.)+\d+)($|\/(\d*))/o ) {
		my @parse = split /\./, $1;
		my $last = ($_ = ($4 || @parse<<3)) > 24 ? 3 : ($_-1)>>3;
		return join '.', reverse( (@parse,(0)x3)[0 .. $last] ), 'in-addr.arpa';
	}

	# If arg looks like IP6 address then map to ip6.arpa space
	if ( $arg =~ /^((\w*:)+)(\w*)($|\/(\d*))/o ) {
		my @parse = split /:/, (reverse "0${1}0${3}"), 9;
		my @xpand = map{/^$/ ? ('0')x(9-@parse) : $_} @parse;
		my $hex = pack 'A4'x8, map{$_.'000'} ('0')x(8-@xpand), @xpand;
		my $len = ($_ = ($5 || @xpand<<4)) > 124 ? 32 : ($_+3)>>2;
		return join '.', split(//, substr($hex,-$len) ), 'ip6.arpa';
	}

	return undef;
}




#
# Some people have reported that Net::DNS dies because AUTOLOAD picks up
# calls to DESTROY.
#
sub DESTROY {}

=head2 qname, zname

    print "qname = ", $question->qname, "\n";
    print "zname = ", $question->zname, "\n";

Returns the domain name.  In dynamic update packets, this field is
known as C<zname> and refers to the zone name.

=head2 qtype, ztype

    print "qtype = ", $question->qtype, "\n";
    print "ztype = ", $question->ztype, "\n";

Returns the record type.  In dymamic update packets, this field is
known as C<ztype> and refers to the zone type (must be SOA).

=head2 qclass, zclass

    print "qclass = ", $question->qclass, "\n";
    print "zclass = ", $question->zclass, "\n";

Returns the record class.  In dynamic update packets, this field is
known as C<zclass> and refers to the zone's class.

=cut

sub AUTOLOAD {
	my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*://o;

	Carp::croak "$name: no such method" unless exists $self->{$name};

	return $self->{$name} unless @_;

	$self->{$name} = shift;
}


sub zname  { &qname;  }
sub ztype  { &qtype;  }
sub zclass { &qclass; }

=head2 print

    $question->print;

Prints the question record on the standard output.

=cut

sub print {	print shift->string, "\n"; }

=head2 string

    print $qr->string, "\n";

Returns a string representation of the question record.

=cut

sub string {
	my $self = shift;
	return "$self->{qname}.\t$self->{qclass}\t$self->{qtype}";
}

=head2 data

    $qdata = $question->data($packet, $offset);

Returns the question record in binary format suitable for inclusion
in a DNS packet.

Arguments are a C<Net::DNS::Packet> object and the offset within
that packet's data where the C<Net::DNS::Question> record is to
be stored.  This information is necessary for using compressed
domain names.

=cut

sub data {
	my ($self, $packet, $offset) = @_;

	my $data = $packet->dn_comp($self->{qname}, $offset);

	$data .= pack 'n', Net::DNS::typesbyname(uc $self->{qtype});
	$data .= pack 'n', Net::DNS::classesbyname(uc $self->{qclass});
	
	return $data;
}

=head1 COPYRIGHT

Copyright (c) 1997-2002 Michael Fuhr. 

Portions Copyright (c) 2002-2004 Chris Reinhardt.

Portions Copyright (c) 2003,2006-2007 Dick Franks.

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::Resolver>, L<Net::DNS::Packet>,
L<Net::DNS::Update>, L<Net::DNS::Header>, L<Net::DNS::RR>,
RFC 1035 Section 4.1.2

=cut

1;
