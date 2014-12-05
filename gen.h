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

#define kCCHTTPRequestMethodGET  0
#define kCCHTTPRequestMethodPOST 1


class wxlog //: public log
{
public:
	static SuperAnimNode *create(std::string theAbsAnimFile,int theId,SuperAnimNodeListener* theListener = NULL);

	wxlog(const wxString& expr, int flags = wxRE_DEFAULT );
	~wxlog();

	static wxString CanonicalizeName(const wxString* name, wxDynamicLibraryCategory cat = wxDL_LIBRARY); 

	void SetLog(wxLog *logger); 

	wxLog *GetOldLog(wxLog *logger) const; 

	wxDynamicLibraryDetails Item( int n );

	bool Load(const wxString& libname, int flags = wxDL_DEFAULT); 

	bool HasSymbol(const wxString& name) const; 

};

class CCCrypto : public ccc
{
public:
    static LUA_STRING* encryptXXTEALua @ createWithUrl (const char* plaintext,int plaintextLength,const char* key,int keyLength);


    static CCHTTPRequest* createWithUrlLua @ createWithUrl (LUA_FUNCTION listener,
                                           const char* url,
                                           int method = kCCHTTPRequestMethodGET,
                                           bool isOpenssl = false);

    static LUA_STRING decryptXXTEALua @ decryptXXTEA (const char* ciphertext,
                                      int ciphertextLength,
                                      const char* key,
                                      int keyLength);

    static LUA_STRING encodeBase64Lua @ encodeBase64 (const char* input, int inputLength);
    static LUA_STRING decodeBase64Lua @ decodeBase64 (const char* input);

    static LUA_STRING MD5Lua @ MD5 (char* input, bool isRawOutput);

    static LUA_STRING MD5FileLua @ MD5File(const char* path);
};

class wxDateTimeArray 
{
wxDateTimeArray( ); 
wxDateTimeArray(const wxDateTimeArray& array ); 

void Add(const wxDateTime& dateTime, size_t copies = 1 ); 
void Alloc(size_t nCount ); 
void Clear( ); 
void Empty( ); 
int GetCount() const; 
void Insert(const wxDateTime& dt, int nIndex, size_t copies = 1 ); 
bool IsEmpty( ); 
wxDateTime Item(size_t nIndex) const; 
wxDateTime Last( ); 
void RemoveAt(size_t nIndex, size_t count = 1 ); 
void Shrink( ); 
}; 