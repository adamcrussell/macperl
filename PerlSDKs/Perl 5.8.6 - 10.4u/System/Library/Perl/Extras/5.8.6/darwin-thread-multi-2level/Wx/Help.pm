#############################################################################
## Name:        ext/help/lib/Wx/Help.pm
## Purpose:     Wx::Help ( pulls in all Wx::Help* stuff )
## Author:      Mattia Barbon
## Modified by:
## Created:     18/03/2001
## RCS-ID:      $Id: Help.pm,v 1.7 2004/10/19 20:28:09 mbarbon Exp $
## Copyright:   (c) 2001-2002 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::Help;

use Wx;
use strict;

use vars qw($VERSION);

$VERSION = '0.01';

Wx::wx_boot( 'Wx::Help', $VERSION );

#
# properly setup inheritance tree
#

no strict;

package Wx::WinHelpController;  @ISA = qw(Wx::HelpControllerBase);
package Wx::HelpControllerHtml; @ISA = qw(Wx::HelpControllerBase);
package Wx::CHMHelpController;  @ISA = qw(Wx::HelpControllerBase);
package Wx::ExtHelpController;  @ISA = qw(Wx::HelpControllerBase);
package Wx::BesthelpController; @ISA = qw(Wx::HelpControllerBase);

package Wx::ContextHelpButton;  @ISA = qw(Wx::BitmapButton);
package Wx::SimpleHelpProvider; @ISA = qw(Wx::HelpProvider);
package Wx::HelpControllerHelpProvider; @ISA = qw(Wx::HelpProvider);

use strict;

1;

# Local variables: #
# mode: cperl #
# End: #
