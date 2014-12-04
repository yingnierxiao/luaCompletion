#include "gen.h"
//--------
enum 
{ 
	wxWINDOWS_OS2, 
	wxUNIX, 
	wxX11, 
	wxPALMOS, 
	wxDOS 
}; 


enum wxDynamicLibraryCategory
{ 
	wxMOTIF_X, 
	wxWINDOWS_OS2, 
	wxUNIX, 
	wxX11, 
	wxPALMOS, 
	wxDOS 
}; 

class wxlog //: public log
{
// public:
	// wxlog(const wxString& expr, int flags = wxRE_DEFAULT );
	// ~wxlog();

	// static wxString CanonicalizeName(const wxString& name, wxDynamicLibraryCategory cat = wxDL_LIBRARY); 

	void SetLog(wxLog *logger); 

	wxLog *GetOldLog() const; 

	wxDynamicLibraryDetails Item( int n );

	bool Load(const wxString& libname, int flags = wxDL_DEFAULT); 

	bool HasSymbol(const wxString& name) const; 

};