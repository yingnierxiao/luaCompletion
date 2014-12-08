class XMLNode
{
public:

   
    /// Get the XMLDocument that owns this XMLNode.
    XMLDocument* GetDocument()              {
        return _document;
    }

    /// Safely cast to an Element, or null.
     XMLElement*        ToElement()     {
        return 0;
    }
    /// Safely cast to Text, or null.
     XMLText*       ToText()        {
        return 0;
    }
    /// Safely cast to a Comment, or null.
     XMLComment*        ToComment()     {
        return 0;
    }
    /// Safely cast to a Document, or null.
     XMLDocument*   ToDocument()    {
        return 0;
    }
    /// Safely cast to a Declaration, or null.
     XMLDeclaration*    ToDeclaration() {
        return 0;
    }
    /// Safely cast to an Unknown, or null.
     XMLUnknown*        ToUnknown()     {
        return 0;
    }

     const XMLElement*      ToElement() const       {
        return 0;
    }
     const XMLText*         ToText() const          {
        return 0;
    }
     const XMLComment*      ToComment() const       {
        return 0;
    }
     const XMLDocument*     ToDocument() const      {
        return 0;
    }
     const XMLDeclaration*  ToDeclaration() const   {
        return 0;
    }
     const XMLUnknown*      ToUnknown() const       {
        return 0;
    }

    /** The meaning of 'value' changes for the specific type.
        @verbatim
        Document:   empty
        Element:    name of the element
        Comment:    the comment text
        Unknown:    the tag contents
        Text:       the text string
        @endverbatim
    */
    const char* Value() const           {
        return _value.GetStr();
    }

    /** Set the Value of an XML node.
        @sa Value()
    */
    void SetValue( const char* val, bool staticMem=false );

    /// Get the parent of this node on the DOM.
    const XMLNode*  Parent() const          {
        return _parent;
    }

    XMLNode* Parent()                       {
        return _parent;
    }

    /// Returns true if this node has no children.
    bool NoChildren() const                 {
        return !_firstChild;
    }


    XMLNode*        FirstChild()            {
        return _firstChild;
    }


    XMLElement* FirstChildElement( const char* value=0 )    {
        return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->FirstChildElement( value ));
    }

   
    XMLNode*        LastChild()                             {
        return const_cast<XMLNode*>(const_cast<const XMLNode*>(this)->LastChild() );
    }

  
    XMLElement* LastChildElement( const char* value=0 ) {
        return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->LastChildElement(value) );
    }

  

    XMLNode*    PreviousSibling()                           {
        return _prev;
    }


    XMLElement* PreviousSiblingElement( const char* value=0 ) {
        return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->PreviousSiblingElement( value ) );
    }

  
    XMLNode*    NextSibling()                               {
        return _next;
    }

  
    XMLElement* NextSiblingElement( const char* value=0 )   {
        return const_cast<XMLElement*>(const_cast<const XMLNode*>(this)->NextSiblingElement( value ) );
    }

    /**
        Add a child node as the last (right) child.
    */
    XMLNode* InsertEndChild( XMLNode* addThis );

    XMLNode* LinkEndChild( XMLNode* addThis )   {
        return InsertEndChild( addThis );
    }
    /**
        Add a child node as the first (left) child.
    */
    XMLNode* InsertFirstChild( XMLNode* addThis );
    /**
        Add a node after the specified child node.
    */
    XMLNode* InsertAfterChild( XMLNode* afterThis, XMLNode* addThis );

    /**
        Delete all the children of this node.
    */
    void DeleteChildren();

    /**
        Delete a child of this node.
    */
    void DeleteChild( XMLNode* node );

    /**
        Make a copy of this node, but not its children.
        You may pass in a Document pointer that will be
        the owner of the new Node. If the 'document' is
        null, then the node returned will be allocated
        from the current Document. (this->GetDocument())

        Note: if called on a XMLDocument, this will return null.
    */
     XMLNode* ShallowClone( XMLDocument* document ) const;

    /**
        Test if 2 nodes are the same, but don't test children.
        The 2 nodes do not need to be in the same Document.

        Note: if called on a XMLDocument, this will return false.
    */
     bool ShallowEqual( const XMLNode* compare ) const;

    /** Accept a hierarchical visit of the nodes in the TinyXML DOM. Every node in the
        XML tree will be conditionally visited and the host will be called back
        via the TiXmlVisitor interface.

        This is essentially a SAX interface for TinyXML. (Note however it doesn't re-parse
        the XML for the callbacks, so the performance of TinyXML is unchanged by using this
        interface versus any other.)

        The interface has been based on ideas from:

        - http://www.saxproject.org/
        - http://c2.com/cgi/wiki?HierarchicalVisitorPattern

        Which are both good references for "visiting".

        An example of using Accept():
        @verbatim
        TiXmlPrinter printer;
        tinyxmlDoc.Accept( &printer );
        const char* xmlcstr = printer.CStr();
        @endverbatim
    */
     bool Accept( XMLVisitor* visitor ) const;

    // internal
     // //char* ParseDeep( char*, StrPair* );
};
