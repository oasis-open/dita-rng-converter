<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditadtd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  xmlns:dita="http://dita.oasis-open.org/architecture/2005/"
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc local rng2ditadtd"
  expand-text="yes"
  version="3.0"
  >
  
  <!-- Overrides to handle special cases in the DTD generation required for
       strict backward compatibility with DITA 1.2 DTDs.
    -->
      
  <xsl:template priority="10" 
    match="dita:domainsContribution[rngfunc:getModuleShortName(ancestor::rng:grammar) = 'strictTaskbody']" 
    mode="domainAttContributionEntityDecl">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- OVERRIDE: Use "taskbody" for the entity name, not the module short name -->
    <xsl:variable name="domainPrefix" as="xs:string" select="'taskbody'"/>
    
    <xsl:variable name="suffix" as="xs:string"
      select="if (rngfunc:getModuleType(root(.)/*) = ('constraint')) 
      then '-constraints' 
      else '-att'"
    />
    
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>&lt;!ENTITY </xsl:text>
    <xsl:sequence select="concat($domainPrefix, $suffix)"/>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>  "</xsl:text><xsl:value-of select="."/><xsl:text>"&#x0a;</xsl:text>
    <xsl:text>&gt;&#x0a;</xsl:text>    
  </xsl:template>
  
  <xsl:template mode="generateDomainsContributionEntityReference" priority="10"
    match="rng:grammar[rngfunc:getModuleShortName(.) = 'strictTaskbody']">
    <xsl:value-of
      select="concat('&amp;', 'taskbody', '-constraints', ';', '&#x0a;')"
    />                            
  </xsl:template>
  
  <!-- no-topic-nesting needs to be a special case. IBM tooling does not handle
       entity declarations with empty replacement text.
    -->
  <xsl:template match="rng:define[@name = 'no-topic-nesting.element'][rng:element]" mode="element-decls" priority="100">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] mode: element-decls: element-defining define, name="{@name}"</xsl:message>
    </xsl:if> 
    <xsl:call-template name="no-topic-nesting-elementdecl"/>    
  </xsl:template>
  
  <xsl:template name="no-topic-nesting-elementdecl"
    match="rng:element[@name = 'no-topic-nesting']" priority="100" mode="element-decls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:text>
&lt;!--                    LONG NAME: No Topic nesting                -->
&lt;!ELEMENT no-topic-nesting EMPTY >

    </xsl:text>
    
  </xsl:template>
  
  <!-- ==========================
       Glossary.dtd, .ent, .mod
       ========================== -->
  
  <xsl:template mode="dtdFile" match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    

    <!-- Generate glossary.dtd shell -->

    <xsl:message>+ [INFO] === Generating DTD shell {$dtdFilename}...</xsl:message>
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:variable name="headerComment" as="element()*"
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdShell'], dita:moduleDesc/dita:headerComment[1])[1]"
    />
    
    <xsl:apply-templates select="$headerComment" mode="header-comment"/>
    
    <!-- This is hard coded because it's invariant. -->
    
<xsl:text>
&lt;!-- NOTE: The glossary.dtd file was misnamed in DITA 1.1. As of 
     DITA 1.2, this file simply redirects to the correctly-named
     file.
  -->
</xsl:text>    
    
    <xsl:choose>
      <xsl:when test="$usePublicIDsInShell">
<xsl:text>
&lt;!ENTITY % glossentryDtd
  PUBLIC "-//OASIS//DTD DITA Glossary Entry//EN" 
         "glossentry.dtd"
>%glossentryDtd;
</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
&lt;!ENTITY % glossentryDtd
  SYSTEM  "glossentry.dtd"
>%glossentryDtd;
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    

    <xsl:text>
&lt;!-- ================= End of </xsl:text>
    <xsl:value-of select="rngfunc:getModuleTitle(.)"/>
    <xsl:text> ================= --></xsl:text>
    
    <xsl:message>+ [INFO] === DTD shell {$dtdFilename} generated.</xsl:message>
    
  </xsl:template>

  <xsl:template mode="entityFile" match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    
    
    <!-- Generate glossary.ent file -->
    
    <xsl:if test="$doDebug"> 
      <xsl:message expand-text="yes">+ [DEBUG] === entityFile: rng:grammar "{base-uri(.)}"</xsl:message>
    </xsl:if>    
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:variable name="headerComment" as="element()*"
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdEnt'], dita:moduleDesc/dita:headerComment[1])[1]"
    />
    
    <xsl:apply-templates select="$headerComment" mode="header-comment"/>
    
    <!-- This is hard coded because it's invariant. -->
    
    <xsl:text>
&lt;!-- NOTE: The glossary.ent file was misnamed in DITA 1.1. As of 
     DITA 1.2, this file simply redirects to the correctly-named
     file.
  -->
</xsl:text>    
    
    <xsl:choose>
      <xsl:when test="$usePublicIDsInShell">
        <xsl:text>
&lt;!ENTITY % glossentryEnt
  PUBLIC "-//OASIS//ENTITIES DITA Glossary Entry//EN" 
         "glossentry.ent"
>%glossentryEnt;
</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
<xsl:text>        
&lt;!ENTITY % glossentryEnt
  SYSTEM  "glossentry.ent"
>%glossentryEnt;
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    
    
    <xsl:text>
&lt;!-- ================= End of </xsl:text>
    <xsl:value-of select="rngfunc:getModuleTitle(.)"/>
    <xsl:text> ================= --></xsl:text>
    
  </xsl:template>
  
  <xsl:template mode="moduleFile" match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    
    
    <!-- Generate glossary.mod file -->
    
    <xsl:if test="$doDebug"> 
      <xsl:message expand-text="yes">+ [DEBUG] === moduleFile: rng:grammar "{base-uri(.)}"</xsl:message>
    </xsl:if>    
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:variable name="headerComment" as="element()*"
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdMod'], dita:moduleDesc/dita:headerComment[1])[1]"
    />
    
    <xsl:apply-templates select="$headerComment" mode="header-comment"/>
    
    <!-- This is hard coded because it's invariant. -->
    
    <xsl:text>
&lt;!-- NOTE: The glossary.mod file was misnamed in DITA 1.1. As of 
     DITA 1.2, this file simply redirects to the correctly-named
     file.
  -->
</xsl:text>    
    
    <xsl:choose>
      <xsl:when test="$usePublicIDsInShell">
        <xsl:text>
&lt;!ENTITY % glossentryMod
  PUBLIC "-//OASIS//ELEMENTS DITA Glossary Entry//EN" 
         "glossentry.mod"
>%glossentryMod;
</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>        
&lt;!ENTITY % glossentryMod
  SYSTEM  "glossentry.mod"
>%glossentryMod;
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    
    
    <xsl:text>
&lt;!-- ================= End of </xsl:text>
    <xsl:value-of select="rngfunc:getModuleTitle(.)"/>
    <xsl:text> ================= --></xsl:text>
    
  </xsl:template>
  
  <!-- ==================================
       Handle "tree" for @collection-type
       on linklist and linkpool
       ================================== -->
  
  <xsl:template match="rng:define[@name = ('linkpool.attributes', 'linklist.attributes')]//rng:attribute[@name = 'collection-type']/rng:choice"
    mode="element-decls" 
    priority="20"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="preceding-sibling::rng:* or 
      parent::rng:*[not(self::rng:define)]/preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:for-each select="rng:*">
      <xsl:if test="not(position()=1)">
        <xsl:text> |&#x0a;</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." mode="#current" >
        <xsl:with-param name="indent" as="xs:integer" tunnel="yes" 
          select="$indent"/>
      </xsl:apply-templates>
    </xsl:for-each>
    <!-- Add option "tree" per TC decision to maintain "tree" only in DTDs -->
    <xsl:text> |&#x0a;</xsl:text>
    <xsl:value-of select="str:indent($indent)"/><xsl:text>tree</xsl:text>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <!-- ============================
       Generate DITAVAL DTD
       ============================ -->
  
  <xsl:template match="rng:grammar[rngfunc:getModuleShortName(.) = 'ditaval']" mode="dtdFile" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] dtdFile: rng:grammar: dtdDir="<xsl:sequence select="$dtdOutputDir"/>"</xsl:message>
    </xsl:if>    
    <xsl:variable name="firstStart" as="element()?"
      select="(//rng:start/rng:ref)[1]"
    />
    <xsl:message>+ [INFO] === Generating DTD shell {$dtdFilename}...</xsl:message>
    
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdShell'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
    />
    
    <!-- The DITAVAL DTD is just hard-coded for now since it doesn't follow the normal DITA pattern. 
    
         It could be generated from the RNG with a little more work.
    -->
    <xsl:text>
<![CDATA[
<!ELEMENT val (style-conflict?, (prop | revprop)*)>

<!ELEMENT style-conflict EMPTY>
<!ATTLIST style-conflict
  foreground-conflict-color CDATA #IMPLIED
  background-conflict-color CDATA #IMPLIED
>


<!ELEMENT prop (startflag?, endflag?)>
<!ATTLIST prop
  att       CDATA       #IMPLIED
  val       CDATA       #IMPLIED
  action    (flag|include|exclude|passthrough)  #REQUIRED
  color     CDATA       #IMPLIED
  backcolor CDATA       #IMPLIED
]]></xsl:text>
<xsl:choose>
  <xsl:when test="$ditaVersion = '1.3'">
    <xsl:text>  style     NMTOKENS    #IMPLIED</xsl:text>
  </xsl:when>
  <xsl:otherwise>
    <xsl:text>  style     (underline|double-underline|italics|overline|bold)       #IMPLIED</xsl:text>
  </xsl:otherwise>
</xsl:choose>
    
<xsl:text><![CDATA[  
  >

<!ELEMENT startflag (alt-text?)>
<!ATTLIST startflag
  imageref  CDATA       #IMPLIED
>

<!ELEMENT endflag (alt-text?)>
<!ATTLIST endflag
  imageref  CDATA       #IMPLIED
>

<!ELEMENT alt-text (#PCDATA)>

<!-- The style attribute should be a color value (either a name, or a SRGB value).
     See below for the supported color names (taken from the XHTML DTD). -->
<!ELEMENT revprop (startflag?, endflag?)>
<!ATTLIST revprop
  val       CDATA       #IMPLIED
  action    (include|passthrough|flag)  #REQUIRED
  changebar CDATA       #IMPLIED
  color     CDATA       #IMPLIED
  backcolor CDATA       #IMPLIED
]]></xsl:text>
<xsl:choose>
  <xsl:when test="$ditaVersion = '1.3'">
    <xsl:text>  style     NMTOKENS    #IMPLIED</xsl:text>
  </xsl:when>
  <xsl:otherwise>
    <xsl:text>  style     (underline|double-underline|italics|overline|bold)       #IMPLIED</xsl:text>
  </xsl:otherwise>
</xsl:choose>
    
<xsl:text><![CDATA[ 
  >

<!-- There are 16 widely known color names with their sRGB values:

    black  = #000000    green  = #008000
    silver = #C0C0C0    lime   = #00FF00
    gray   = #808080    olive  = #808000
    white  = #FFFFFF    yellow = #FFFF00
    maroon = #800000    navy   = #000080
    red    = #FF0000    blue   = #0000FF
    purple = #800080    teal   = #008080
    fuchsia= #FF00FF    aqua   = #00FFFF
-->

]]>      
    </xsl:text>
  </xsl:template>
  
  <!-- Don't handle reference to glossentry.rng from glossary.rng -->
  
  <xsl:template mode="getIncludedModules" priority="100" 
    match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary'][rngfunc:getModuleType(.) = 'topicshell']" 
    >
    <!-- Don't process references in the glossary.rng module. -->
  </xsl:template>
  
</xsl:stylesheet>