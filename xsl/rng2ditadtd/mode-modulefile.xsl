<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditadtd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:dita="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  exclude-result-prefixes="xs xd rng rnga relpath a str ditaarch dita rngfunc local rng2ditadtd"
  version="3.0"  >
  <!-- ====================================================
       Mode "moduleFile"
       
       ==================================================== -->
  
  <!-- ==============================
       .mod file generation mode
       ============================== -->
  
  <xsl:template match="/" mode="moduleFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] moduleFile: / ...</xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="#current" >
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="rng:grammar" mode="moduleFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:message>+ [DEBUG] moduleFile: rng:grammar = rngfunc:getModuleType(.)="<xsl:value-of select="rngfunc:getModuleType(.)"/>"</xsl:message>
    <xsl:variable name="doDebug" as="xs:boolean" select="rngfunc:getModuleShortName(.) = ('par_highlightDomain-c')"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] moduleFile: rng:grammar ...</xsl:message>
    </xsl:if>
    
    <xsl:variable name="moduleTitle" 
      select="rngfunc:getModuleTitle(.)" 
      as="xs:string"/>
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(.)"
    />
    <xsl:variable name="domainPrefix" 
      as="xs:string"
      select="rngfunc:getModuleShortName(.)"
    /> 
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdMod'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
    />
    <xsl:if test="$moduleShortName = ('topic', 'map')">
      <xsl:call-template name="generateArchAttsDecls"/>
    </xsl:if>
    <xsl:if test="not($moduleShortName = ('metaDecl', 'tblDecl'))">
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                   ELEMENT NAME ENTITIES                       -->
&lt;!-- ============================================================= -->

</xsl:text>
    </xsl:if>
    <!-- Special Case: the commonElements.mod file references commonElements.ent,
         which contains the element type name entities for the 
         common elements. This organization isn't required by DTD processing
         rules but is just how it was done.
         
      -->
    <xsl:choose>
      <xsl:when test="$moduleShortName = 'commonElements'">
        <xsl:call-template name="generateCommonElementsDeclsPart1"/>
      </xsl:when>
      <xsl:when test="$moduleShortName = 'topic'">
        <xsl:call-template name="generateTopicDeclsPart1"/>      
      </xsl:when>
      <xsl:when test="$moduleShortName = ('metaDecl')">
        <!-- metaDecl.mod does not include it's element name entities but tblDecl does -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="element-name-entities" select="rng:define[rng:element]"/>       
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:if test="$moduleShortName = 'topic'">
      <xsl:call-template name="generateTopicDeclsPart2"/>      
    </xsl:if>
    
    <!-- For modules that integrate foreign vocabularies, find any rng:externalRef
         elements and generate the corresponding external parameter entity reference.
      -->
    
    <xsl:apply-templates select="//rng:externalRef" mode="externalRef"/>
    
    <xsl:if test="$moduleShortName = 'map'">
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    COMMON ATTLIST SETS                        -->
&lt;!-- ============================================================= -->  

</xsl:text>
      
      <xsl:apply-templates mode="generate-parment-decl-from-define" 
        select=".//rng:define[starts-with(@name, 'topicref-atts')]">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>  
      
      <xsl:text>
    
&lt;!-- ============================================================= -->
&lt;!--                    MODULES CALLS                              -->
&lt;!-- ============================================================= -->
  
</xsl:text>
      
      <xsl:apply-templates mode="element-decls" 
        select="rng:include[@href = ('commonElementsMod.rng', 'metaDeclMod.rng')]">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      
      <xsl:text>      
  
&lt;!-- ============================================================= -->
&lt;!--                    DOMAINS ATTRIBUTE OVERRIDE                 -->
&lt;!-- ============================================================= -->

&lt;!ENTITY included-domains 
  "" 
> 
</xsl:text>      
    </xsl:if>
    
    <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    ELEMENT DECLARATIONS                       -->
&lt;!-- ============================================================= -->

</xsl:text>    
    
    <!-- Process all defines in the order they occur, except
         those that define @class attributes, which come at the
         end of the module file.
         
         The info-types defines need to be processed first so that they
         precede any possible reference to them.
         
      -->
    
    <xsl:if test="$moduleShortName != 'topic'">
      <!-- For topic.mod, the info-types parameter entity is hard-coded in a different location -->
      <xsl:apply-templates mode="generate-parment-decl-from-define"
        select="rng:define[ends-with(@name, 'info-types')]"
      />
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="$moduleShortName = 'topic'">
        <!-- All the includes for the topic module are hard coded above -->
        <xsl:apply-templates mode="element-decls" 
          select="(rng:define) except 
          (rng:define[.//rng:attribute[@name='class']],
          rng:define[ends-with(@name, 'info-types')])"
          >
          <xsl:with-param name="domainPfx" select="$domainPrefix" tunnel="yes" as="xs:string" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$moduleShortName = 'map'">
        <!-- Common attribute lists have already been handled -->
        <xsl:apply-templates mode="element-decls" 
          select="(rng:define) except 
          (rng:define[starts-with(@name, 'topicref-atts')],
          rng:define[.//rng:attribute[@name='class']],
          rng:define[ends-with(@name, 'info-types')])"
          >
          <xsl:with-param name="domainPfx" select="$domainPrefix" tunnel="yes" as="xs:string" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="element-decls" 
          select="(rng:define | rng:include) except 
          (rng:define[.//rng:attribute[@name='class']],
          rng:define[ends-with(@name, 'info-types')])"
          >
          <xsl:with-param name="domainPfx" select="$domainPrefix" tunnel="yes" as="xs:string" />
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--             SPECIALIZATION ATTRIBUTE DECLARATIONS             -->
&lt;!-- ============================================================= -->
  
</xsl:text>    
    
    <xsl:apply-templates mode="class-att-decls" 
      select="rng:define[.//rng:attribute[@name='class']]"/>
    
    <xsl:text>
&lt;!-- ================== End of </xsl:text><xsl:value-of select="$moduleTitle"/><xsl:text> ==================== -->&#x0a; </xsl:text>    
  </xsl:template>
  
  <!-- ========================================================
       Named template for module generation components
       ======================================================== -->
  
  <xsl:template name="generateArchAttsDecls">
    <xsl:text><![CDATA[
<!-- ============================================================= -->
<!--                   ARCHITECTURE ENTITIES                       -->
<!-- ============================================================= -->

<!-- default namespace prefix for DITAArchVersion attribute can be
     overridden through predefinition in the document type shell   -->
<!ENTITY % DITAArchNSPrefix
  "ditaarch"
>

<!-- must be instanced on each topic type                          -->
<!ENTITY % arch-atts 
             "xmlns:%DITAArchNSPrefix; 
                        CDATA
                                  #FIXED 'http://dita.oasis-open.org/architecture/2005/'
              %DITAArchNSPrefix;:DITAArchVersion
                         CDATA
                                  ']]></xsl:text><xsl:value-of select="$ditaVersion"/><xsl:text><![CDATA['
  "
>


]]></xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:grammar[rngfunc:getModuleType(.) = 'constraint']" mode="moduleFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] moduleFile: (constraint) rng:grammar ...</xsl:message>
    </xsl:if>
    
    <xsl:variable name="moduleTitle" 
      select="rngfunc:getModuleTitle(.)" 
      as="xs:string"/>
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(.)"
    />
    <xsl:variable name="domainPrefix" 
      as="xs:string"
      select="rngfunc:getModuleShortName(.)"
    /> 
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:apply-templates select="dita:moduleDesc" mode="header-comment"/>
    
    <xsl:apply-templates mode="domainAttContributionEntityDecl"
      select="dita:moduleDesc/dita:moduleMetadata/dita:domainsContribution"
      >
      <xsl:with-param name="domainPrefix" select="$domainPrefix" as="xs:string" />
    </xsl:apply-templates>
    
    <!-- Handle contents of any constraints 
        
         Because of the way DTDs work, the module needs to declare
         element-type-name parameter entities for each of the element
         types referenced from any content models because the 
         constraint is included before the base module that would otherwise
         declare those parameter entities. These redundant declarations
         are not required in the RNG.
         
    -->
    <xsl:apply-templates select="rng:include/rng:define"
      mode="make-element-type-name-parments"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>  
    </xsl:apply-templates>
    
    <xsl:text>&#x0a;</xsl:text>
    
    <xsl:apply-templates select="rng:include | rng:define" mode="generate-parment-decl-from-define">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>  
    </xsl:apply-templates>
    
    <xsl:text>
&lt;!-- ================== </xsl:text><xsl:value-of select="$moduleTitle"/><xsl:text> ==================== -->&#x0a; </xsl:text>    
    
  </xsl:template>  
  
  <xsl:template match="comment()" mode="moduleFile" >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- FIXME: I don't think we want to echo comments from the RNG to the DTD -->
    <xsl:choose>
      <xsl:when test="not(following::rng:grammar)">
        <xsl:text>&lt;!-- </xsl:text><xsl:value-of select="translate(.,'&lt;&gt;','')"/><xsl:text> -->&#x0a;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- Suppress comments in moduleFile mode -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
    
  <xsl:template name="generateCommonElementsDeclsPart1">
    <xsl:text>
&lt;!ENTITY % commonDefns</xsl:text>
    <xsl:choose>
      <xsl:when test="$doUsePublicIDsInShell">
        <xsl:text>
  PUBLIC "-//OASIS//ENTITIES DITA </xsl:text>          
        <xsl:value-of select="$ditaVersion"/><xsl:text> Common Elements//EN" </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
  SYSTEM </xsl:text>          
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>         "commonElements.ent" 
>%commonDefns;
</xsl:text>
    
  </xsl:template>   
  
  <xsl:template name="generateTopicDeclsPart1">
    <xsl:text>
&lt;!--                    Definitions of declared elements           -->
&lt;!ENTITY % topicDefns</xsl:text>
    <xsl:choose>
      <xsl:when test="$doUsePublicIDsInShell">
        <xsl:text>
    PUBLIC "-//OASIS//ENTITIES DITA </xsl:text><xsl:value-of select="$ditaVersion"/><xsl:text> Topic Definitions//EN"</xsl:text>          
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
    SYSTEM</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> "topicDefn.ent" 
>%topicDefns;

&lt;!--                      Content elements common to map and topic -->
&lt;!ENTITY % commonElements
</xsl:text>
    <xsl:choose>
      <xsl:when test="$doUsePublicIDsInShell">
        <xsl:text>
  PUBLIC "-//OASIS//ELEMENTS DITA </xsl:text><xsl:value-of select="$ditaVersion"/><xsl:text> Common Elements//EN"</xsl:text> 
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
  SYSTEM
</xsl:text>
      </xsl:otherwise>
    </xsl:choose><xsl:text>
         "commonElements.mod" 
>%commonElements;

&lt;!--                       MetaData Elements, plus indexterm       -->
&lt;!ENTITY % metaXML 
</xsl:text>
    <xsl:choose>
      <xsl:when test="$doUsePublicIDsInShell">
        <xsl:text>  PUBLIC "-//OASIS//ELEMENTS DITA </xsl:text><xsl:value-of select="$ditaVersion"/><xsl:text> Metadata//EN"</xsl:text> 
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
    SYSTEM</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>
         "metaDecl.mod" 
>%metaXML;
</xsl:text> 
  </xsl:template>
  
  <xsl:template name="generateTopicDeclsPart2">
    
    <xsl:text><![CDATA[
<!-- ============================================================= -->
<!--                COMMON ENTITY DECLARATIONS                     -->
<!-- ============================================================= -->

<!-- Use of this entity is deprecated; the nbsp entity will be 
     removed in DITA 2.0.                                          -->
<!ENTITY nbsp                   "&#xA0;"                             >


<!-- ============================================================= -->
<!--                    NOTATION DECLARATIONS                      -->
<!-- ============================================================= -->
<!--                    DITA uses the direct reference model; 
                        notations may be added later as required   -->


<!-- ============================================================= -->
<!--                    STRUCTURAL MEMBERS                         -->
<!-- ============================================================= -->


<!ENTITY % info-types 
  "topic
  "
> 

<!-- ============================================================= -->
<!--                    COMMON ATTLIST SETS                        -->
<!-- ============================================================= -->

]]></xsl:text>
    
    <!-- FIXME: The common attribute lists (relational-atts, rel-atts)
            should go here to exactly match 1.2 organization
            but they are processed in the 
            element declaration processing below.
  -->
    
    <xsl:text><![CDATA[
<!-- ============================================================= -->
<!--                    SPECIALIZATION OF DECLARED ELEMENTS        -->
<!-- ============================================================= -->

<!ENTITY % topic-info-types 
  "%info-types;
  "
>

<!-- ============================================================= -->
<!--                    DOMAINS ATTRIBUTE OVERRIDE                 -->
<!-- ============================================================= -->

<!ENTITY included-domains 
  ""
>

]]></xsl:text>
  </xsl:template> 
  
</xsl:stylesheet>