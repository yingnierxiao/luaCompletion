#include "gen.h"

class SuperAnimNodeListener
{
public:
    virtual void OnAnimSectionEnd(int theId, std::string theLabelName){}
};
class SuperAnimNode : public CCSprite
{

public:

	// unsigned char   ReadUInt8();
	// void    WriteUInt8(unsigned char u1Data);

    SuperAnimNode();
    ~SuperAnimNode();
    static SuperAnimNode *create(std::string theAbsAnimFile, int theId, SuperAnimNodeListener *theListener=NULL);

    bool Init(std::string theAbsAnimFile, int theId, SuperAnimNodeListener *theListener);
    void draw();
    void update(float dt);
    void setFlipX(bool isFlip);
    void setFlipY(bool isFlip);

    bool PlaySection(std::string theLabel);
    float GetSectionTime(std::string theLabel);
    void Pause();
    void Resume();
    bool IsPause();
    bool IsPlaying();
    int GetCurFrame();
    std::string GetCurSectionName();
    bool HasSection(std::string theLabelName);

};
