#############################################################################
## Name:        lib/Wx/App.pm
## Purpose:     Wx::App class
## Author:      Mattia Barbon
## Modified by:
## Created:     25/11/2000
## RCS-ID:      $Id: App.pm,v 1.14 2004/10/19 20:28:11 mbarbon Exp $
## Copyright:   (c) 2000-2003 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::App;

@ISA = qw(Wx::_App);

use strict;

# this allows multiple ->new calls and it is an horrible kludge to allow
# Wx::Perl::SplashFast to work "better"; see also App.xs:Start
sub new {
  my $this;

  my $class = ref( $_[0] ) || $_[0];
  if( ref( $Wx::wxTheApp ) ) {
    bless $Wx::wxTheApp, $class;
    $this = $Wx::wxTheApp;
  } else {
    $this = $_[0]->SUPER::new();
    bless $this, $class;
    $Wx::wxTheApp = $this;
  }

  $this->SetAppName($_[0]); # reasonable default for Wx::ConfigBase::Get

  my $ret = Wx::_App::Start($this,$this->can('OnInit'));
  Wx::_croak( 'OnInit must return a true return value' )
    # why does OnInit always return 0 on Mac?
    unless $Wx::_platform == 4 || $ret;

  $this;
}

sub OnInit {
  0;
}

1;

# Local variables: #
# mode: cperl #
# End: #
