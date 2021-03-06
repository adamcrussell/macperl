package ExtUtils::MM_Win32;

use strict;


=head1 NAME

ExtUtils::MM_Win32 - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Win32; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=cut 

use Config;
use File::Basename;
use File::Spec;
use ExtUtils::MakeMaker qw( neatvalue );

use vars qw(@ISA $VERSION $BORLAND $GCC $DMAKE $NMAKE);

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
@ISA = qw( ExtUtils::MM_Any ExtUtils::MM_Unix );
$VERSION = '1.08';

$ENV{EMXSHELL} = 'sh'; # to run `commands`

$BORLAND = 1 if $Config{'cc'} =~ /^bcc/i;
$GCC     = 1 if $Config{'cc'} =~ /^gcc/i;
$DMAKE = 1 if $Config{'make'} =~ /^dmake/i;
$NMAKE = 1 if $Config{'make'} =~ /^nmake/i;


=head2 Overridden methods

=over 4

=item B<dlsyms>

=cut

sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($funclist) = $attribs{FUNCLIST} || $self->{FUNCLIST} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     q!	$(PERLRUN) -MExtUtils::Mksymlists \\
     -e "Mksymlists('NAME'=>\"!, $self->{NAME},
     q!\", 'DLBASE' => '!,$self->{DLBASE},
     # The above two lines quoted differently to work around
     # a bug in the 4DOS/4NT command line interpreter.  The visible
     # result of the bug was files named q('extension_name',) *with the
     # single quotes and the comma* in the extension build directories.
     q!', 'DL_FUNCS' => !,neatvalue($funcs),
     q!, 'FUNCLIST' => !,neatvalue($funclist),
     q!, 'IMPORTS' => !,neatvalue($imports),
     q!, 'DL_VARS' => !, neatvalue($vars), q!);"
!);
    }
    join('',@m);
}

=item replace_manpage_separator

Changes the path separator with .

=cut

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}


=item B<maybe_command>

Since Windows has nothing as simple as an executable bit, we check the
file extension.

The PATHEXT env variable will be used to get a list of extensions that
might indicate a command, otherwise .com, .exe, .bat and .cmd will be
used by default.

=cut

sub maybe_command {
    my($self,$file) = @_;
    my @e = exists($ENV{'PATHEXT'})
          ? split(/;/, $ENV{PATHEXT})
	  : qw(.com .exe .bat .cmd);
    my $e = '';
    for (@e) { $e .= "\Q$_\E|" }
    chop $e;
    # see if file ends in one of the known extensions
    if ($file =~ /($e)$/i) {
	return $file if -e $file;
    }
    else {
	for (@e) {
	    return "$file$_" if -e "$file$_";
	}
    }
    return;
}


=item B<find_tests>

The Win9x shell does not expand globs and I'll play it safe and assume
other Windows variants don't either.

So we do it for them.

=cut

sub find_tests {
    return join(' ', <t\\*.t>);
}


=item B<init_DIRFILESEP>

Using \ for Windows.

=cut

sub init_DIRFILESEP {
    my($self) = shift;

    # The ^ makes sure its not interpreted as an escape in nmake
    $self->{DIRFILESEP} = $NMAKE ? '^\\' :
                          $DMAKE ? '\\\\'
                                 : '\\';
}

=item B<init_others>

Override some of the Unix specific commands with portable
ExtUtils::Command ones.

Also provide defaults for LD and AR in case the %Config values aren't
set.

LDLOADLIBS's default is changed to $Config{libs}.

Adjustments are made for Borland's quirks needing -L to come first.

=cut

sub init_others {
    my ($self) = @_;

    # Used in favor of echo because echo won't strip quotes. :(
    $self->{ECHO}     ||= $self->oneliner('print qq{@ARGV}', ['-l']);
    $self->{ECHO_N}   ||= $self->oneliner('print qq{@ARGV}');

    $self->{TOUCH}    ||= '$(PERLRUN) -MExtUtils::Command -e touch';
    $self->{CHMOD}    ||= '$(PERLRUN) -MExtUtils::Command -e chmod'; 
    $self->{CP}       ||= '$(PERLRUN) -MExtUtils::Command -e cp';
    $self->{RM_F}     ||= '$(PERLRUN) -MExtUtils::Command -e rm_f';
    $self->{RM_RF}    ||= '$(PERLRUN) -MExtUtils::Command -e rm_rf';
    $self->{MV}       ||= '$(PERLRUN) -MExtUtils::Command -e mv';
    $self->{NOOP}     ||= 'rem';
    $self->{TEST_F}   ||= '$(PERLRUN) -MExtUtils::Command -e test_f';
    $self->{DEV_NULL} ||= '> NUL';

    # technically speaking, these should be in init_main()
    $self->{LD}     ||= $Config{ld} || 'link';
    $self->{AR}     ||= $Config{ar} || 'lib';

    $self->SUPER::init_others;

    # Setting SHELL from $Config{sh} can break dmake.  Its ok without it.
    delete $self->{SHELL};

    $self->{LDLOADLIBS} ||= $Config{libs};
    # -Lfoo must come first for Borland, so we put it in LDDLFLAGS
    if ($BORLAND) {
        my $libs = $self->{LDLOADLIBS};
        my $libpath = '';
        while ($libs =~ s/(?:^|\s)(("?)-L.+?\2)(?:\s|$)/ /) {
            $libpath .= ' ' if length $libpath;
            $libpath .= $1;
        }
        $self->{LDLOADLIBS} = $libs;
        $self->{LDDLFLAGS} ||= $Config{lddlflags};
        $self->{LDDLFLAGS} .= " $libpath";
    }

    return 1;
}


=item init_platform (o)

Add MM_Win32_VERSION.

=item platform_constants (o)

=cut

sub init_platform {
    my($self) = shift;

    $self->{MM_Win32_VERSION} = $VERSION;
}

sub platform_constants {
    my($self) = shift;
    my $make_frag = '';

    foreach my $macro (qw(MM_Win32_VERSION))
    {
        next unless defined $self->{$macro};
        $make_frag .= "$macro = $self->{$macro}\n";
    }

    return $make_frag;
}


=item special_targets (o)

Add .USESHELL target for dmake.

=cut

sub special_targets {
    my($self) = @_;

    my $make_frag = $self->SUPER::special_targets;

    $make_frag .= <<'MAKE_FRAG' if $DMAKE;
.USESHELL :
MAKE_FRAG

    return $make_frag;
}


=item static_lib (o)

Changes how to run the linker.

The rest is duplicate code from MM_Unix.  Should move the linker code
to its own method.

=cut

sub static_lib {
    my($self) = @_;
    return '' unless $self->has_link_code;

    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DIRFILESEP).exists
	$(RM_RF) $@
END

    # If this extension has its own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push @m, <<'MAKE_FRAG' if $self->{MYEXTLIB};
	$(CP) $(MYEXTLIB) $@
MAKE_FRAG

    push @m,
q{	$(AR) }.($BORLAND ? '$@ $(OBJECT:^"+")'
			  : ($GCC ? '-ru $@ $(OBJECT)'
			          : '-out:$@ $(OBJECT)')).q{
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)\extralibs.ld
};

    # Old mechanism - still available:
    push @m, <<'MAKE_FRAG' if $self->{PERL_SRC} && $self->{EXTRALIBS};
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" >> $(PERL_SRC)\ext.libs
MAKE_FRAG

    push @m, "\n", $self->dir_target('$(INST_ARCHAUTODIR)');
    join('', @m);
}


=item dynamic_lib (o)

Complicated stuff for Win32 that I don't understand. :(

=cut

sub dynamic_lib {
    my($self, %attribs) = @_;
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || ($BORLAND ? 'c0d32.obj': '');
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($ldfrom) = '$(LDFROM)';
    my(@m);

# one thing for GCC/Mingw32:
# we try to overcome non-relocateable-DLL problems by generating
#    a (hopefully unique) image-base from the dll's name
# -- BKS, 10-19-1999
    if ($GCC) { 
	my $dllname = $self->{BASEEXT} . "." . $self->{DLEXT};
	$dllname =~ /(....)(.{0,4})/;
	my $baseaddr = unpack("n", $1 ^ $2);
	$otherldflags .= sprintf("-Wl,--image-base,0x%x0000 ", $baseaddr);
    }

    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
OTHERLDFLAGS = '.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)$(DIRFILESEP).exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
');
    if ($GCC) {
      push(@m,  
       q{	dlltool --def $(EXPORT_LIST) --output-exp dll.exp
	$(LD) -o $@ -Wl,--base-file -Wl,dll.base $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp
	dlltool --def $(EXPORT_LIST) --base-file dll.base --output-exp dll.exp
	$(LD) -o $@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp });
    } elsif ($BORLAND) {
      push(@m,
       q{	$(LD) $(LDDLFLAGS) $(OTHERLDFLAGS) }.$ldfrom.q{,$@,,}
       .($DMAKE ? q{$(PERL_ARCHIVE:s,/,\,) $(LDLOADLIBS:s,/,\,) }
		 .q{$(MYEXTLIB:s,/,\,),$(EXPORT_LIST:s,/,\,)}
		: q{$(subst /,\,$(PERL_ARCHIVE)) $(subst /,\,$(LDLOADLIBS)) }
		 .q{$(subst /,\,$(MYEXTLIB)),$(subst /,\,$(EXPORT_LIST))})
       .q{,$(RESFILES)});
    } else {	# VC
      push(@m,
       q{	$(LD) -out:$@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) }
      .q{$(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) -def:$(EXPORT_LIST)});
    }
    push @m, '
	$(CHMOD) $(PERM_RWX) $@
';

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}

=item clean

Clean out some extra dll.{base,exp} files which might be generated by
gcc.  Otherwise, take out all *.pdb files.

=cut

sub clean
{
    my ($self) = shift;
    my $s = $self->SUPER::clean(@_);
    my $clean = $GCC ? 'dll.base dll.exp' : '*.pdb';
    $s .= <<END;
clean ::
	-\$(RM_F) $clean

END
    return $s;
}

=item init_linker

=cut

sub init_linker {
    my $self = shift;

    $self->{PERL_ARCHIVE}       = "\$(PERL_INC)\\$Config{libperl}";
    $self->{PERL_ARCHIVE_AFTER} = '';
    $self->{EXPORT_LIST}        = '$(BASEEXT).def';
}


=item perl_script

Checks for the perl program under several common perl extensions.

=cut

sub perl_script {
    my($self,$file) = @_;
    return $file if -r $file && -f _;
    return "$file.pl"  if -r "$file.pl" && -f _;
    return "$file.plx" if -r "$file.plx" && -f _;
    return "$file.bat" if -r "$file.bat" && -f _;
    return;
}


=item xs_o (o)

This target is stubbed out.  Not sure why.

=cut

sub xs_o {
    return ''
}


=item pasthru (o)

All we send is -nologo to nmake to prevent it from printing its damned
banner.

=cut

sub pasthru {
    my($self) = shift;
    return "PASTHRU = " . ($NMAKE ? "-nologo" : "");
}


=item oneliner (o)

These are based on what command.com does on Win98.  They may be wrong
for other Windows shells, I don't know.

=cut

sub oneliner {
    my($self, $cmd, $switches) = @_;
    $switches = [] unless defined $switches;

    # Strip leading and trailing newlines
    $cmd =~ s{^\n+}{};
    $cmd =~ s{\n+$}{};

    $cmd = $self->quote_literal($cmd);
    $cmd = $self->escape_newlines($cmd);

    $switches = join ' ', @$switches;

    return qq{\$(PERLRUN) $switches -e $cmd};
}


sub quote_literal {
    my($self, $text) = @_;

    # I don't know if this is correct, but it seems to work on
    # Win98's command.com
    $text =~ s{"}{\\"}g;

    # dmake eats '{' inside double quotes and leaves alone { outside double
    # quotes; however it transforms {{ into { either inside and outside double
    # quotes.  It also translates }} into }.  The escaping below is not
    # 100% correct.
    if( $DMAKE ) {
        $text =~ s/{/{{/g;
        $text =~ s/}}/}}}/g;
    }

    return qq{"$text"};
}


sub escape_newlines {
    my($self, $text) = @_;

    # Escape newlines
    $text =~ s{\n}{\\\n}g;

    return $text;
}


=item max_exec_len

Using 31K, a safe number gotten from Windows 2000.

=cut

sub max_exec_len {
    my $self = shift;

    return $self->{_MAX_EXEC_LEN} ||= 31 * 1024;
}


=item os_flavor

Windows is Win32.

=cut

sub os_flavor {
    return('Win32');
}


1;
__END__

=back

=cut 


