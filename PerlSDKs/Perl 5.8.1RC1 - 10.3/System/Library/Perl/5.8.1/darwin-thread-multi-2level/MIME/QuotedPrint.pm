#
# $Id: QuotedPrint.pm,v 2.13 2003/05/13 18:22:09 gisle Exp $

package MIME::QuotedPrint;

=head1 NAME

MIME::QuotedPrint - Encoding and decoding of quoted-printable strings

=head1 SYNOPSIS

 use MIME::QuotedPrint;

 $encoded = encode_qp($decoded);
 $decoded = decode_qp($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into the
Quoted-Printable encoding specified in RFC 2045 - I<MIME (Multipurpose
Internet Mail Extensions)>.  The Quoted-Printable encoding is intended
to represent data that largely consists of bytes that correspond to
printable characters in the ASCII character set.  Non-printable
characters (as defined by english americans) are represented by a
triplet consisting of the character "=" followed by two hexadecimal
digits.

The following functions are provided:

=over 4

=item encode_qp($str)

=item encode_qp($str, $eol)

This function will return an encoded version of the string given as
argument.  The second argument is the line ending sequence to use (it
is optional and defaults to C<"\n">).

=item decode_qp($str);

This function will return the plain text version of the string given
as argument.  Lines with be "\n" terminated.

=back


If you prefer not to import these routines into your namespace you can
call them as:

  use MIME::QuotedPrint ();
  $encoded = MIME::QuotedPrint::encode($decoded);
  $decoded = MIME::QuotedPrint::decode($encoded);

=head1 COPYRIGHT

Copyright 1995-1997,2002-2003 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw(@ISA @EXPORT $VERSION);
if (ord('A') == 193) { # on EBCDIC machines we need translation help
    require Encode;
}

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encode_qp decode_qp);

use Carp qw(croak);

$VERSION = "2.20";

use MIME::Base64;  # try to load XS version of encode_qp
unless (defined &encode_qp) {
    *encode_qp = \&old_encode_qp;
    *decode_qp = \&old_decode_qp;
}

sub old_encode_qp ($;$)
{
    my $res = shift;
    if ($] >= 5.006) {
	require bytes;
	if (bytes::length($res) > length($res) ||
	    ($] >= 5.008 && $res =~ /[^\0-\xFF]/)) {
	    croak("The Quoted-Printable encoding is only defined for bytes");
	}
    }

    my $eol = shift;
    $eol = "\n" unless defined($eol) || length($eol);

    # Do not mention ranges such as $res =~ s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;
    # since that will not even compile on an EBCDIC machine (where ord('!') > ord('<')).
    if (ord('A') == 193) { # EBCDIC style machine
        if (ord('[') == 173) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp1047',$_)))) }
        		   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 187) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('posix-bc',$_)))) }
        		   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
        elsif (ord('[') == 186) {
            $res =~ s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$1))))/eg;  # rule #2,#3
            $res =~ s/([ \t]+)$/
              join('', map { sprintf("=%02X", ord(Encode::encode('iso-8859-1',Encode::decode('cp37',$_)))) }
        		   split('', $1)
              )/egm;                        # rule #3 (encode whitespace at eol)
        }
    }
    else { # ASCII style machine
        $res =~  s/([^ \t\n!"#\$%&'()*+,\-.\/0-9:;<>?\@A-Z[\\\]^_`a-z{|}~])/sprintf("=%02X", ord($1))/eg;  # rule #2,#3
        $res =~ s/([ \t]+)$/
          join('', map { sprintf("=%02X", ord($_)) }
    		   split('', $1)
          )/egm;                        # rule #3 (encode whitespace at eol)
    }

    # rule #5 (lines must be shorter than 76 chars, but we are not allowed
    # to break =XX escapes.  This makes things complicated :-( )
    my $brokenlines = "";
    $brokenlines .= "$1=$eol"
	while $res =~ s/(.*?^[^\n]{73} (?:
		 [^=\n]{2} (?! [^=\n]{0,1} $) # 75 not followed by .?\n
		|[^=\n]    (?! [^=\n]{0,2} $) # 74 not followed by .?.?\n
		|          (?! [^=\n]{0,3} $) # 73 not followed by .?.?.?\n
	    ))//xsm;

    "$brokenlines$res";
}


sub old_decode_qp ($)
{
    my $res = shift;
    $res =~ s/\r\n/\n/g;            # normalize newlines
    $res =~ s/[ \t]+\n/\n/g;        # rule #3 (trailing space must be deleted)
    $res =~ s/=\n//g;               # rule #5 (soft line breaks)
    if (ord('A') == 193) { # EBCDIC style machine
        if (ord('[') == 173) {
            $res =~ s/=([\da-fA-F]{2})/Encode::encode('cp1047',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
        }
        elsif (ord('[') == 187) {
            $res =~ s/=([\da-fA-F]{2})/Encode::encode('posix-bc',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
        }
        elsif (ord('[') == 186) {
            $res =~ s/=([\da-fA-F]{2})/Encode::encode('cp37',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
        }
    }
    else { # ASCII style machine
        $res =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
    }
    $res;
}

# Set up aliases so that these functions also can be called as
#
# MIME::QuotedPrint::encode();
# MIME::QuotedPrint::decode();

*encode = \&encode_qp;
*decode = \&decode_qp;

1;
