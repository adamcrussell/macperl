# Mail::Util.pm
#
# Copyright (c) 1995-2001 Graham Barr <gbarr@pobox.com>. All rights reserved.
# Copyright (c) 2002-2003 Mark Overmeer <mailtools@overmeer.net>
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::Util;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use AutoLoader ();
use Exporter ();

BEGIN {
    require 5.000;

    $VERSION = "1.65";

    *AUTOLOAD = \&AutoLoader::AUTOLOAD;
    @ISA = qw(Exporter);

    @EXPORT_OK = qw(read_mbox maildomain mailaddress);
}

1;

sub Version { $VERSION }

=head1 NAME

Mail::Util - mail utility functions

=head1 SYNOPSIS

use Mail::Util qw( ... );

=head1 DESCRIPTION

This package provides several mail related utility functions. Any function
required must by explicitly listed on the use line to be exported into
the calling package.

=head2 read_mbox( $file )

Read C<$file>, a binmail mailbox file, and return a list of  references.
Each reference is a reference to an array containg one message.

=head2 maildomain()

Attempt to determine the current uers mail domain string via the following
methods

=over 4

=item *  Look for the MAILDOMAIN enviroment variable, which can be set from outside the program.

=item *  Look for a sendmail.cf file and extract DH parameter

=item *  Look for a smail config file and usr the first host defined in hostname(s)

=item *  Try an SMTP connect (if Net::SMTP exists) first to mailhost then localhost

=item *  Use value from Net::Domain::domainname (if Net::Domain exists)

=back

=head2 mailaddress()

Return a guess at the current users mail address. The user can force
the return value by setting the MAILADDRESS environment variable.

WARNING:
When not supplied via the environment variable, <mailaddress> looks at
various configuration files and other environmental data. Although this
seems to be smart behavior, this is not predictable enough (IMHO) to
be used.  Please set the MAILADDRESS explicitly, and do not trust on
the "automatic detection", even when that produces a correct address
(on the moment)

=head1 AUTHOR

Graham Barr.

Maintained by Mark Overmeer <mailtools@overmeer.net>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Mark Overmeer, 1995-2001 Graham Barr. All rights
reserved. This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

__END__

sub read_mbox {
    my $file  = shift;
    my @mail  = ();
    my $mail  = [];
    my $blank = 1;
    local *FH;
    local $_;

    open(FH,"< $file") or
	do {
	    require Carp;
	    Carp::croak("cannot open '$file': $!\n");
	};

    while(<FH>) {
	if($blank && /\AFrom .*\d{4}/) {
	    push(@mail, $mail) if scalar(@{$mail});
	    $mail = [ $_ ];
	    $blank = 0;
	}
	else {
	    $blank = m#\A\Z#o ? 1 : 0;
	    push(@{$mail}, $_);
	}
    }

    push(@mail, $mail) if scalar(@{$mail});

    close(FH);

    return wantarray ? @mail : \@mail;
}


sub maildomain {

    ##
    ## return imediately if already found
    ##

    return $domain
	if(defined $domain);

    ##
    ## Get mail domain from environment
    ##

    $domain = $ENV{MAILDOMAIN};

    return $domain
       if(defined $domain);

    ##
    ## Try sendmail config file if exists
    ##

    local *CF;
    local $_;
    my @sendmailcf = qw(/etc
			/etc/sendmail
			/etc/ucblib
			/etc/mail
			/usr/lib
			/var/adm/sendmail);

    my $config = (grep(-r, map("$_/sendmail.cf", @sendmailcf)))[0];

    if(defined $config && open(CF,$config)) {
	my %var;
	while(<CF>) {
	    if(my ($v, $arg) = /^D([a-zA-Z])([\w.\$\-]+)/) {
		$arg =~ s/\$([a-zA-Z])/exists $var{$1} ? $var{$1} : '$'.$1/eg;
		$var{$v} = $arg;
	    }
	}
	close(CF);
	$domain = $var{j} if defined $var{j};
	$domain = $var{M} if defined $var{M};

        $domain = $1
            if($domain && $domain =~ m/([A-Za-z0-9](?:[\.\-A-Za-z0-9]+))/ );

	return $domain
	    if(defined $domain);
    }

    ##
    ## Try smail config file if exists
    ##

    if(open(CF,"/usr/lib/smail/config")) {
	while(<CF>) {
	    if(/\A\s*hostnames?\s*=\s*(\S+)/) {
		$domain = (split(/:/,$1))[0];
		last;
	    }
	}
	close(CF);

	return $domain
	    if(defined $domain);
    }

    ##
    ## Try a SMTP connection to 'mailhost'
    ##

    if(eval { require Net::SMTP }) {
	my $host;

	foreach $host (qw(mailhost localhost)) {
	    my $smtp = eval { Net::SMTP->new($host) };

	    if(defined $smtp) {
		$domain = $smtp->domain;
		$smtp->quit;
		last;
	    }
	}
    }

    ##
    ## Use internet(DNS) domain name, if it can be found
    ##

    unless(defined $domain) {
	if(eval { require Net::Domain } ) {
	    $domain = Net::Domain::domainname();
	}
    }

    $domain = "localhost"
	unless(defined $domain);

    return $domain;
}


sub mailaddress {

    ##
    ## Return imediately if already found
    ##

    return $mailaddress
	if(defined $mailaddress);

    ##
    ## Get user name from environment
    ##

    $mailaddress = $ENV{MAILADDRESS};

    unless ($mailaddress || $^O ne 'MacOS') {
	require Mac::InternetConfig;
	Mac::InternetConfig->import();

	$mailaddress = $InternetConfig{kICEmail()};
    }

    $mailaddress ||= $ENV{USER}    ||
                     $ENV{LOGNAME} ||
                     eval {getpwuid($>)} ||
                     "postmaster";

    ##
    ## Add domain if it does not exist
    ##

    $mailaddress .= '@' . maildomain()
	unless($mailaddress =~ /\@/);

    $mailaddress =~ s/(^.*<|>.*$)//g;

    $mailaddress;
}
