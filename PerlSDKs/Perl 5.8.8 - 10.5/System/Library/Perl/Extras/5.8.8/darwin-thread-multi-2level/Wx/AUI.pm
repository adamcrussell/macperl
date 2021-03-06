#############################################################################
## Name:        ext/aui/lib/Wx/AUI.pm
## Purpose:     Wx::AUI and related classes
## Author:      Mattia Barbon
## Modified by:
## Created:     11/11/2006
## RCS-ID:      $Id: AUI.pm,v 1.3 2006/11/12 17:35:25 mbarbon Exp $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::AUI;

use strict;

our $VERSION = '0.01';

Wx::load_dll( 'adv' );
Wx::load_dll( 'aui' );
Wx::wx_boot( 'Wx::AUI', $VERSION );

SetEvents();

#
# properly setup inheritance tree
#

no strict;

package Wx::AuiManager;    @ISA = qw(Wx::EvtHandler);
package Wx::AuiNotebook;   @ISA = qw(Wx::Control);
package Wx::AuiManagerEvent; @ISA = qw(Wx::Event);
package Wx::AuiNotebookEvent; @ISA = qw(Wx::NotifyEvent);

1;
