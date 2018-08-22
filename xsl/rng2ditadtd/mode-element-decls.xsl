<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditadtd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:dita="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  exclude-result-prefixes="xs xd rng rnga relpath a str ditaarch dita rngfunc local rng2ditadtd"
  version="3.0"  >
  <!-- =============================================================
       Implements modes:
       
       - element-decls 
       - generate-element-type-parameter-entities
       - generate-element-decl
      
       This mode is the general mode for handling defines
       ============================================================= -->

  <xsl:template match="rng:include" mode="element-decls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdOutputDir" as="xs:string" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] rng:include, element-decls: dtdOutputDir="<xsl:value-of select="$dtdOutputDir"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="thisModuleURI" as="xs:string"
      select="rngfunc:getGrammarUri(root(.)/*)"
    />
    <xsl:variable name="targetUri" as="xs:string"
      select="relpath:newFile(relpath:getParent($thisModuleURI), @href)"
    />
    <xsl:variable name="module" select="document($targetUri)"/>
    
    <xsl:choose>
      <xsl:when test="$module">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: rng:include - Handling module "<xsl:value-of select="@href"/>"</xsl:message>
        </xsl:if>
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG]   referencingGrammarUrl="<xsl:value-of select="$thisModuleURI"/>"</xsl:message>
        </xsl:if>
        
        <xsl:apply-templates mode="#current" select="a:documentation">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>    
        
        <xsl:apply-templates select="$module" mode="entityDeclaration">
          <xsl:with-param 
            name="entityType" 
            as="xs:string" 
            tunnel="yes"
            select="'mod'"
          />
          <xsl:with-param name="referencingGrammarUrl" tunnel="yes" as="xs:string"
            select="$thisModuleURI"
          />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [ERROR] Failed to resolve grammar reference <xsl:value-of select="@href"/> using full URL "<xsl:value-of select="$targetUri"/>"</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Make header comment from the RNG include documentation -->
  <xsl:template mode="element-decls" match="rng:include/a:documentation">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="text" as="node()*">
      <xsl:value-of select="a:documentation"/>
    </xsl:variable>
    <xsl:text>&#x0a;&lt;!-- </xsl:text>
    <xsl:variable name="len" as="xs:integer" select="string-length($text)"/>
    <xsl:choose>
      <xsl:when test="$len lt 61">
        <xsl:variable name="centeredStr">
          <xsl:value-of select="if (string-length($text) lt 61)
            then str:indent((61 - string-length($text)) idiv 2)
            else ''
            "/>
          <xsl:value-of select="$text"/>
        </xsl:variable>
        <xsl:value-of select="str:pad($centeredStr, 61)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> --></xsl:text>
    
  </xsl:template>
    
  <!-- Class attributes are handled in a separate mode -->
  
  <xsl:template match="rng:define[.//rng:attribute[@name='class']]" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define @name="class": ignoring.</xsl:message>
    </xsl:if>
  </xsl:template>
  
  
  <xsl:template match="rng:define[starts-with(@name, concat(rngfunc:getModuleShortName(ancestor::rng:grammar), '-'))]" 
    mode="element-decls" priority="30"
  >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define, @name starts with module short name: ignoring.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  
  <xsl:template match="rng:define[@combine = 'choice']" mode="element-decls" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Domain integration entity. Not output in the DTD. -->
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define @combine = 'choice'": ignoring.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="rng:define[ends-with(@name, '.content') or ends-with(@name, '.attributes')]" 
    mode="element-decls" priority="15">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- content and attlist declarations are handled from within the rng:element processing 
      
      -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define @name ends with .content or .attributes: processing maybe.</xsl:message>
    </xsl:if>
    
    <xsl:if test="ends-with(@name, '.attributes')">
      <!-- WEK: This is a bit of a hack to handle a case that only occurs within 
                the tblDecl.mod file in the OASIS-provided modules. The case
                could occur in non-OASIS modules but should not, because you shouldn't
                use ".attributes" for anything other than the main attributes declaration
                entity.
        -->
      <xsl:if test="starts-with(@name, 'dita.')">
        <xsl:next-match/><!-- Handle dita.*.attributes from tblDecl.mod" -->
      </xsl:if>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and key('attlistIndex',@name)]" 
    mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- .attlist pointing to .attributes, ignore -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define is a reference to .attributes, ignoring</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and key('definesByName',rng:ref/@name)/rng:element]" 
    mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- reference to element name in this module, will be in the entity file -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: reference to ann element name in this module: ignoring.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and not(key('definesByName',rng:ref/@name)) and ends-with(rng:ref/@name, '.element')]" 
    mode="element-decls" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- reference to element name in another module, will be in entity file -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define reference to an element name in another module: ignoring.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="rng:define[rng:notAllowed]" 
    mode="element-decls" priority="30">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- The DITA spec doesn't say anything about the use of notAllowed, so just ignore this declaration for now -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define containing rng:notAllowed: Ignoring.</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <!-- ================================
       Process defines that result in 
       DTD declarations.
       ================================ -->
  
  <xsl:template match="rng:define[rng:element]" mode="element-decls" priority="15">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] mode: element-decls: element-defining define, name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>    
    <xsl:apply-templates mode="#current" select="rng:element">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="rng:define[not(.//rng:attribute[@name='class'])]" mode="element-decls" priority="8">
    <!-- Main template for generating parameter entity declarations from defines. 
    
         Note that the .content and .attributes handling is driven from within the rng:element
    -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="domainPfx" tunnel="yes" as="xs:string" /><!-- FIXME: I think domainPfx is no longer useful. -->
        
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] mode: element-decls: rng:define name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$domainPfx and not($domainPfx='') and starts-with(@name, $domainPfx)">
        <!-- Should never get here so this is belt to go with suspenders -->
        <!-- Domain extension pattern, not output in the .mod file (goes in shell DTDs) -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="generate-parment-decl-from-define" select=".">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="rng:zeroOrMore" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
        
    <xsl:if test="not(parent::rng:define) or preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="indent" as="xs:integer" tunnel="yes" 
        select="$indent + 1"/>
    </xsl:apply-templates>
    <xsl:text>)*</xsl:text>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:text>,&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:oneOrMore" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="indent" as="xs:integer" tunnel="yes" 
        select="$indent + 1"/>
    </xsl:apply-templates>
    <xsl:text>)+</xsl:text>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:text>,&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:group" mode="element-decls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: rng:group</xsl:message>
    </xsl:if>
    <xsl:if test="preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="indent" as="xs:integer" tunnel="yes" 
        select="$indent + 1"/>
    </xsl:apply-templates>
    <xsl:text>)</xsl:text>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:text>,&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:attribute/rng:choice" mode="element-decls" priority="15">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: rng:attribute[name="<xsl:value-of select="../@name"/>"]/rng:choice</xsl:message>
    </xsl:if>
    
    <xsl:if test="preceding-sibling::rng:* or 
      parent::rng:*[not(self::rng:define)]/preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls:    Applying templates with $connector set to " |"...</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="rng:*" mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="indent" as="xs:integer" tunnel="yes" 
        select="$indent"/>
      <xsl:with-param name="connector" as="xs:string" select="' |'"/>
    </xsl:apply-templates>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:optional" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    <xsl:param name="isAttSet" as="xs:boolean" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: rng:option</xsl:message>
    </xsl:if>    
    
    <xsl:choose>
      <xsl:when test="not($isAttSet)">
        <!-- optional element content -->
        <xsl:if test="preceding-sibling::rng:*">
          <xsl:value-of select="str:indent($indent)"/>
        </xsl:if>
        <xsl:text>(</xsl:text>
        <xsl:apply-templates mode="#current" >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="indent" select="$indent + 1" as="xs:integer" tunnel="yes"/>
        </xsl:apply-templates>
        <xsl:text>)?</xsl:text>
        <xsl:if test="count(following-sibling::rng:*) gt 0">
          <xsl:text>,&#x0a;</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <!-- optional attribute value -->
        <xsl:apply-templates mode="#current" >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
        <xsl:if test="count(following-sibling::rng:*) gt 0">
          <xsl:text>&#x0a;</xsl:text>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Choice within a define with exactly one rng child. This should be a content model 
       contribution pattern like data.cnt. It cannot have parens around the whole
       choice group.
    -->
  <xsl:template match="rng:define[not(ends-with(@name, '.content'))]/rng:choice[count(../rng:*) = 1]" mode="element-decls" priority="15">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: define/choice that is the only child of its parent:
<xsl:sequence select="."/>        
      </xsl:message>
    </xsl:if>
    
      <xsl:apply-templates select="rng:*" mode="#current" >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="connector" as="xs:string" select="' |'"/>
      </xsl:apply-templates>      
  </xsl:template>
  
  <!-- Any choice child of rng:define that doesn't match the preceding template.
    -->
  <xsl:template mode="element-decls" priority="10" name="choice-element-decls"
    match="rng:define//rng:choice"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] *** element-decls: rng:define//rng:choice:
<xsl:sequence select="."/>        
      </xsl:message>
    </xsl:if>
    <xsl:if test="preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:text>(</xsl:text>    
    <xsl:apply-templates select="rng:*" mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="indent" as="xs:integer" tunnel="yes" select="$indent + 1"/>
      <xsl:with-param name="connector" as="xs:string" select="' |'"/>
    </xsl:apply-templates>      
    <xsl:text>)</xsl:text>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:text>,&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="element-decls" priority="10"
    match="rng:interleave"
    >   
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    <!-- RNG interleave is like SGML "and" connector: elements can occur in any
         order but can only occur once.
         
         Without generating the factorial of the content model, the closest
         analog in DTD is a repeating OR group, which will validate any
         instance also valid against the RNG but will allow instances that are
         not valid against the RNG.
      -->
    <xsl:for-each select=".">
      <xsl:call-template name="choice-element-decls">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:text>*</xsl:text><!-- Make the choice a repeating group -->
  </xsl:template>

  <!-- FIXME: This set of matches is a bit of a hack to handle
       the case as for remedy in troubleshooting. The proper
       fix is to have the parens generated not by the occurence
       indicating element but by the group. Unfortunately, that's
       a rather significant refactor.
    -->
  <xsl:template mode="element-decls" priority="20"
    match="rng:optional/rng:choice[not(preceding-sibling::rng:*)] | 
    rng:zeroOrMore/rng:choice[not(preceding-sibling::rng:*)] | 
    rng:oneOrMore/rng:choice[not(preceding-sibling::rng:*)]
           "
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    
    <!-- Choice has its parens and occurrence indicator provided by the containing element
         element.
      -->
    <xsl:apply-templates select="rng:*" mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
     <xsl:with-param name="connector" as="xs:string" select="' |'"/>
    </xsl:apply-templates>      
  </xsl:template>

  <xsl:template match="rng:ref" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    <xsl:param name="isAttSet" as="xs:boolean" tunnel="yes"/>
    <xsl:param name="connector" as="xs:string" select="','"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: <xsl:value-of select="concat(name(../..), '/', name(..))"/>, ref name="<xsl:value-of select="@name"/>"</xsl:message>
      <xsl:message>+ [DEBUG]                connector="<xsl:value-of select="$connector"/>"</xsl:message>
    </xsl:if>
    
    <xsl:if test="preceding-sibling::rng:*">
      <!-- NOTE: It is up to the processor of the group
                 this ref must be part of to emit
                 a newline after whatever precedes this ref. 
      -->
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="@name='any'">
        <xsl:text>ANY </xsl:text>
      </xsl:when>
      <xsl:when test="not(node()) and key('definesByName',@name)/rng:element" >
        <!-- reference to element name -->
        <xsl:value-of select="key('definesByName',@name)/rng:element/@name" />
        <xsl:if test="count(following-sibling::rng:*) gt 0">
          <xsl:value-of select="$connector"/>
        </xsl:if>        
      </xsl:when>
      <xsl:when test="not(node()) and not(key('definesByName',@name)) and ends-with(@name, '.element')" >
        <!-- reference to element name in another module -->
        <xsl:value-of select="substring-before(@name,'.element')" />
        <xsl:if test="count(following-sibling::rng:*) gt 0">
          <xsl:value-of select="$connector"/>
        </xsl:if>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="entRef" as="node()*">
          <xsl:text>%</xsl:text><xsl:value-of select="@name" /><xsl:text>;</xsl:text>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="not($isAttSet) and 
                          parent::rng:define and 
                          (count(../rng:*) > 1 or ends-with(../@name, '.content'))
                          and not(../@name = 'entry.content')">
            <xsl:text>(</xsl:text>
            <xsl:sequence select="$entRef"/>
            <xsl:text>)</xsl:text>
            <xsl:if test="count(following-sibling::rng:*) gt 0">
              <xsl:value-of select="$connector"/>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$entRef"/>
            <xsl:if test="not($isAttSet) and 
                          (count(following-sibling::rng:*) gt 0)">
              <xsl:value-of select="$connector"/>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="rng:externalRef" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    <xsl:param name="isAttSet" as="xs:boolean" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: rng:externalRef, href="<xsl:value-of select="@href"/>"</xsl:message>
    </xsl:if>

    <!-- I'm not sure this check is sufficient but it's good enough for now -->
    <xsl:variable name="sep" as="xs:string"
      select="if (parent::rng:choice)
        then ' |' else ','
      "
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG]  element-decls: rng:externalRef, sep="<xsl:value-of select="$sep"/>"</xsl:message>
    </xsl:if>
    
    <xsl:if test="preceding-sibling::rng:*">
      <!-- NOTE: It is up to the processor of the group
                 this ref must be part of to emit
                 a newline after whatever precedes this ref. 
      -->
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    
    <!-- External refs are to grammars that are not merged, so we need to get
         the list of allowed start elements and emit them here as
         options in the current group.
      -->
    
    <xsl:variable name="elementTypeNames" as="xs:string*"
       select="rngfunc:getStartElementsForExternalRef(., $doDebug)"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: elementTypeNames != '' ="<xsl:value-of select="$elementTypeNames != ''"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: elementTypeNames="<xsl:value-of select="$elementTypeNames"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="nsPrefix" as="xs:string?"
      select="@dita:namespacePrefix"
    />
    <xsl:if test="not($nsPrefix)">
      <xsl:message> - [WARN] No @dita:namespacePrefix for rng:externalRef with href "<xsl:value-of select="@href"/>".</xsl:message>
      <xsl:message> - [WARN]    Foreign vocabularies must be in a namespace and must be prefixed to avoid collision with DITA-defined names.</xsl:message>
    </xsl:if>
    <xsl:variable name="nsPrefixString" as="xs:string" select="if ($nsPrefix) then concat($nsPrefix, ':') else 'ns1:'"/>
    <xsl:for-each select="$elementTypeNames">
      <xsl:sequence select="concat($nsPrefixString, .)"/>
      <xsl:if test="position() > 1">
        <xsl:sequence select="concat($sep, '&#x0a;', str:indent($indent))"/>
      </xsl:if>
    </xsl:for-each>
    
    <xsl:if test="not(position() = last())">
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:text" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="connector" as="xs:string" select="','"/>
    <!-- NOTE: #PCDATA must always be the first token in a repeating OR
         group so it will never be indented. -->
    
    <xsl:text>#PCDATA</xsl:text>
    <xsl:if test="count(following-sibling::rng:*) gt 0">
      <xsl:sequence select="$connector"/>
      <xsl:sequence select="'&#x0a;'"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:value" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" tunnel="yes"/>
    <xsl:param name="connector" as="xs:string?" select="()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: <xsl:value-of select="concat(name(..), '/', name(.))"/>: "<xsl:value-of select="."/>"</xsl:message>
      <xsl:message>+ [DEBUG] element-decls:   connector="<xsl:value-of select="$connector"/></xsl:message>
    </xsl:if>
    <xsl:if test="preceding-sibling::rng:*">
      <xsl:value-of select="str:indent($indent)"/>
    </xsl:if>
    <xsl:value-of select="." />
    <xsl:if test="exists(following-sibling::rng:*)">
      <xsl:value-of select="$connector"/>
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:data" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:choose>
      <xsl:when test="@type='string'">
        <xsl:value-of select="'CDATA'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@type" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="rng:empty" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:choose>
      <xsl:when test="ancestor::rng:element">
        <!-- empty element content -->
        <xsl:text>EMPTY</xsl:text>
      </xsl:when>
      <xsl:when test="ends-with(ancestor::rng:define/@name, '.content')">
        <!-- empty element content in parameter entity -->
        <xsl:text>EMPTY</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <!-- empty attribute value -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="rng:attribute" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!--
      <!ENTITY % data-element-atts
             '%univ-atts;
              name 
                        CDATA 
                                  #IMPLIED
              scope 
                        (external | 
                         local | 
                         peer | 
                         -dita-use-conref-target) 
                                  #IMPLIED'
               xml:space
                        (preserve)
                                  #FIXED 
                                  'preserve'
        >

      -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: attribute "<xsl:value-of select="@name"/>":
<xsl:sequence select="."/>        
      </xsl:message>
    </xsl:if>
    <xsl:variable name="attributePos">
      <xsl:number level="any" from="rng:define"        
        count="rng:define/rng:attribute | 
               rng:optional | 
               rng:define/rng:ref"/>
    </xsl:variable>
    <xsl:if test="$attributePos > 1">
      <!-- The generator of the attlist decl or parameter entity
           has to ensure a newline before the attribute
        -->
      <xsl:value-of select="str:indent(15)"/>
    </xsl:if>
    <xsl:value-of select="@name" />
    <xsl:text>&#x0a;</xsl:text>
    <xsl:value-of select="str:indent(26)"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: Constructing attribute declaration details...</xsl:message>
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="not(rng:*)">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: No child rng:* elements, attribute must be CDATA</xsl:message>
        </xsl:if>
        <xsl:text>CDATA</xsl:text>
      </xsl:when>
      <xsl:when test="count(*)=1 and rng:value">
        <!-- Fixed attribute. A fixed attribute can be declared as an enumeration of
             one item and then the default is set to that same value.
             
             The effect in RNG is that the attribute can only have this one value.
             
             In DTDs you could also have a CDATA attribute with a fixed default. 
             This only occurs in DITA (so far) in the declaration of @CLASS attributes,
             which are special cased in the RNG-to-DTD transform.
          -->
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: Exactly 1 child and it's rng:value.</xsl:message>
        </xsl:if>
        <xsl:text>(</xsl:text>
        <xsl:apply-templates mode="#current" >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="indent" select="26" as="xs:integer" tunnel="yes"/>
        </xsl:apply-templates>
        <xsl:text>)</xsl:text>
        <xsl:if test="@rnga:defaultValue">
          <xsl:text>&#x0a;</xsl:text>
          <xsl:value-of select="str:indent(36)"/>
          <xsl:text>#FIXED </xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: All other attribute configurations. Applying templates in mode element-decls</xsl:message>
        </xsl:if>
        <xsl:apply-templates mode="#current" >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="indent" select="27" as="xs:integer" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="@rnga:defaultValue">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: Have a default value, putting it out.</xsl:message>
        </xsl:if>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:value-of select="str:indent(36)"/>
        <xsl:text>'</xsl:text>
        <xsl:value-of select="@rnga:defaultValue" />
        <xsl:text>'</xsl:text>
      </xsl:when>
      <xsl:when test="local-name(..)='optional'">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: Attribute is optional, emitting #IMPLIED.</xsl:message>
        </xsl:if>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:value-of select="str:indent(36)"/>
        <xsl:text>#IMPLIED</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] element-decls: Attribute must be, emitting #REQUIRED.</xsl:message>
        </xsl:if>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:value-of select="str:indent(36)"/>
        <xsl:text>#REQUIRED</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position() != last()">
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>
  

  <!-- ================================
       Element declaration generation
       ================================ -->
  <xsl:template match="rng:element" mode="element-decls" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Generate the content and attribute list parameter entities: -->
    <!-- Generate the element type and attribute list declarations -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-decls: rng:element, name="<xsl:value-of select="@name"/>" </xsl:message>
    </xsl:if>
    <xsl:variable name="longName" as="xs:string"
      select="if (@ditaarch:longName) 
      then @ditaarch:longName
      else concat(upper-case(substring(@name, 1, 1)), substring(@name, 2))"
    />
    <xsl:text>&lt;!--</xsl:text>
    <xsl:value-of select="str:indent(20)"/>
    <xsl:text>LONG NAME: </xsl:text>
    <xsl:value-of select="str:pad($longName, 31)"/>
    <xsl:text> --&gt;&#x0a;</xsl:text>
    
    <!-- .content and .attributes parameter entity declarations: -->
    <xsl:apply-templates mode="generate-element-type-parameter-entities" 
      select="rng:ref[ends-with(@name, '.content')], 
      rng:ref[ends-with(@name, '.attlist')]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="tagname" tunnel="yes" as="xs:string" select="@name"/>
    </xsl:apply-templates>
    
    <!-- Element type and attribute list declarations. -->
    <xsl:apply-templates select="rng:ref[ends-with(@name, '.content')]" mode="generate-element-decl">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="tagname" tunnel="yes" as="xs:string" select="@name"/>
    </xsl:apply-templates>
    <!-- NOTE: in the RNG, the reference in the element decl is to .attlist, not .attributes. -->
    <xsl:apply-templates select="rng:ref[ends-with(@name, '.attlist')]" mode="generate-attlist-decl">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="tagname" tunnel="yes" as="xs:string" select="@name"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:attribute//rnga:documentation" mode="element-decls" >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
  
  <xsl:template mode="generate-element-type-parameter-entities" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="define" as="element()?" 
      select="key('definesByName', @name)[1]"
    />
    <xsl:choose>
      <xsl:when test="string(@name) = ('arch-atts', 'domains-att') and count($define) = 0">
        <!-- Silently ignore: these references are a special case -->
      </xsl:when>
      <xsl:when test="count($define) = 0">        
        <xsl:message> - [WARN] generate-element-type-parameter-entities: rng:ref - No rng:define element for referenced name "<xsl:value-of select="@name"/>".</xsl:message>
      </xsl:when>
      <xsl:when test="ends-with($define/@name, '.attlist')">
        <!-- .attlist define is always a reference to the .attributes definition -->
        <xsl:apply-templates select="$define/rng:ref" mode="#current">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="indent" as="xs:integer"
          select="if (ends-with(@name, '.content')) then 23 else 14"
        />
        <xsl:apply-templates select="$define" mode="generate-parment-decl-from-define">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="indent" as="xs:integer" select="$indent"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="generate-element-decl" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="tagname" tunnel="yes" as="xs:string"/>
    <xsl:text>&lt;!ELEMENT  </xsl:text>
    <xsl:value-of select="$tagname" />
    <xsl:text> </xsl:text>
    <xsl:value-of select="concat('%', @name, ';')"/>
    <xsl:text>&gt;&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="rng:notAllowed" priority="-0.9" mode="element-decls">
    <xsl:message> - [WARN] element-decls: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" />: <xsl:sequence select=".." /></xsl:message>
  </xsl:template>
  
  <xsl:template match="rng:*" priority="-1" mode="element-decls">
    <xsl:message> - [WARN] element-decls: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" />: <xsl:sequence select="." /></xsl:message>
  </xsl:template>
</xsl:stylesheet>