/////////////////////////////////////////////////////////////////////////////
// Name:        cpp/event.h
// Purpose:     C++ helpers for user-defined events
// Author:      Mattia Barbon
// Modified by:
// Created:     30/03/2002
// RCS-ID:      $Id: event.h 2057 2007-06-18 23:03:00Z mbarbon $
// Copyright:   (c) 2002-2004, 2006-2007 Mattia Barbon
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#include <wx/event.h>

#include "cpp/v_cback.h"

class wxPlEvent : public wxEvent
{
    WXPLI_DECLARE_DYNAMIC_CLASS( wxPlEvent );
    WXPLI_DECLARE_V_CBACK();
public:
    wxPlEvent( const char* package, int id, wxEventType eventType )
        : wxEvent( id, eventType ),
          m_callback( "Wx::PlEvent" )
    {
        m_callback.SetSelf( wxPli_make_object( this, package ), true );
    }

    virtual ~wxPlEvent()
    {
        m_callback.DeleteSelf( false );
    }

    virtual wxEvent* Clone() const;
};

wxEvent* wxPlEvent::Clone() const
{
    dTHX;
    wxPlEvent* self = (wxPlEvent*)this;

    if( wxPliVirtualCallback_FindCallback( aTHX_ &self->m_callback, "Clone" ) )
    {
        SV* ret = wxPliVirtualCallback_CallCallback
            ( aTHX_ &self->m_callback, G_SCALAR, NULL );
        wxPlEvent* clone =
            (wxPlEvent*)wxPli_sv_2_object( aTHX_ ret, "Wx::PlEvent" );
        
        return clone;
    }

    return 0;
}

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPlEvent, wxEvent );

class wxPlCommandEvent : public wxCommandEvent
{
    WXPLI_DECLARE_DYNAMIC_CLASS( wxPlCommandEvent );
    WXPLI_DECLARE_V_CBACK();
public:
    wxPlCommandEvent( const char* package, int id, wxEventType eventType )
        : wxCommandEvent( id, eventType ),
          m_callback( "Wx::PlCommandEvent" )
    {
        m_callback.SetSelf( wxPli_make_object( this, package ), true );
    }

    virtual ~wxPlCommandEvent()
    {
        m_callback.DeleteSelf( false );
    }

    virtual wxEvent* Clone() const;
};

wxEvent* wxPlCommandEvent::Clone() const
{
    dTHX;
    wxPlCommandEvent* self = (wxPlCommandEvent*)this;

    if( wxPliVirtualCallback_FindCallback( aTHX_ &self->m_callback, "Clone" ) )
    {
        SV* ret = wxPliVirtualCallback_CallCallback
            ( aTHX_ &self->m_callback, G_SCALAR, NULL );
        wxPlCommandEvent* clone = (wxPlCommandEvent*)
            wxPli_sv_2_object( aTHX_ ret, "Wx::PlCommandEvent" );

        return clone;
    }

    return 0;
}

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPlCommandEvent, wxCommandEvent );

class wxPlThreadEvent : public wxEvent
{
    WXPLI_DECLARE_DYNAMIC_CLASS( wxPlThreadEvent );
public:
    static void SetStash( SV* hv_ref )
    {
        m_hv = (HV*)SvRV( hv_ref );
    }
    static HV* GetStash() { return m_hv; }

    wxPlThreadEvent() : m_data( 0 ) {}
    wxPlThreadEvent( pTHX_ const char* package, int id, wxEventType eventType,
                     SV* data )
        : wxEvent( id, eventType )
    {
        PL_lockhook( aTHX_ (SV*)GetStash() );
        PL_sharehook( aTHX_ data );
        int data_id;
        char buffer[30];
        size_t length;
        for(;;)
        {
            data_id = rand();
            length = sprintf( buffer, "%d", data_id );
            if( !hv_exists( GetStash(), buffer, length ) )
                break;
        }
        SV** dst = hv_fetch( GetStash(), buffer, length, 1 );
        sv_setsv( *dst, data );
        mg_set( *dst );
        m_data = data_id;    
    }

    wxPlThreadEvent( const wxPlThreadEvent& e )
        : wxEvent( e ),
          m_data( e.m_data )
    { }

    ~wxPlThreadEvent()
    { 
        if( !m_data )
            return;

        dTHX;

        ENTER;
        SAVETMPS;

        PL_lockhook( aTHX_ (SV*)m_hv );

        char buffer[30];
        size_t length = sprintf( buffer, "%d", m_data );

        hv_delete( m_hv, buffer, length, G_DISCARD );

        FREETMPS;
        LEAVE;
    }

    int _GetData() const { return m_data; }

    SV* GetData() const
    {
        dTHX;

        if( !m_data )
            return &PL_sv_undef;

        PL_lockhook( aTHX_ (SV*)m_hv );

        char buffer[30];
        size_t length = sprintf( buffer, "%d", m_data );

        SV** value = hv_fetch( m_hv, buffer, length, 0 );
        if( !value )
            return NULL;
        mg_get( *value );
        SvREFCNT_inc( *value );

        return *value;
    }

    virtual wxEvent* Clone() const;
private:
    int m_data;
    static HV* m_hv;
};

wxEvent* wxPlThreadEvent::Clone() const
{
    wxEvent* clone = new wxPlThreadEvent( *this );
    ((wxPlThreadEvent*)this)->m_data = 0;

    return clone;
}

HV* wxPlThreadEvent::m_hv = NULL;

wxPliSelfRef* wxPliGetSelfForwxPlThreadEvent( wxObject* object ) { return 0; }
// XXX HACK!
#if wxUSE_EXTENDED_RTTI
const wxClassInfo* wxPlThreadEvent::ms_classParents[] =
    { &wxEvent::ms_classInfo , NULL };
wxPliClassInfo wxPlThreadEvent::ms_classInfo(
    ms_classParents, (wxChar*)wxT( "wxPlPlThreadEvent"),
    (int)sizeof(wxPlThreadEvent), NULL,
    (wxPliGetCallbackObjectFn) wxPliGetSelfForwxPlThreadEvent );
#elif WXPERL_W_VERSION_GE( 2, 5, 1 )
wxPliClassInfo wxPlThreadEvent::ms_classInfo(
    (wxChar*)wxT( "wxPlPlThreadEvent"), &wxEvent::ms_classInfo,
    NULL, (int)sizeof(wxPlThreadEvent),
    (wxPliGetCallbackObjectFn) wxPliGetSelfForwxPlThreadEvent );
#else
wxPliClassInfo wxPlThreadEvent::sm_classwxPlThreadEvent(
    (wxChar*)wxT( "wxPlPlThreadEvent"), (wxChar*)wxT("wxEvent"),
    (wxChar*)NULL, (int)sizeof(wxPlThreadEvent),
    (wxPliGetCallbackObjectFn) wxPliGetSelfForwxPlThreadEvent );
#endif

// local variables: //
// mode: c++ //
// end: //
