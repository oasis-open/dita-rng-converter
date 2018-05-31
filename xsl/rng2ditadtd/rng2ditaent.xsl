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
  exclude-result-prefixes="xs xd rng rnga relpath a ditaarch str rngfunc rng2ditadtd"
  version="2.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to DITA DTD Converter</xd:p>
      <xd:p><xd:b>Created on:</xd:b> Feb 16, 2013</xd:p>
      <xd:p><xd:b>Authors:</xd:b> ekimber, pleblanc</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
      shells and produces from them the entity file
        that reflect the RNG definitions and conform to the DITA 1.3
        DTD coding requirements.
      </xd:p>
    </xd:desc>
  </xd:doc>

  <!-- ==============================
       .ent file generation mode
       ============================== -->

  <xsl:template mode="entityFile" match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="node()" />
  </xsl:template>

  <xsl:template mode="entityFile" match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" 
      as="document-node()*"
      tunnel="yes"
    />
    <xsl:if test="$doDebug"> 
      <xsl:message>+ [DEBUG] === entityFile: rng:grammar <xsl:value-of select="@origURI"/></xsl:message>
    </xsl:if>    
    <xsl:variable name="moduleTitle" 
      select="rngfunc:getModuleTitle(.)" 
      as="xs:string"/>
    <xsl:variable name="moduleShortName" 
      select="rngfunc:getModuleShortName(.)" 
      as="xs:string"/>
    <xsl:variable name="domainValue" as="xs:string?" 
      select="rngfunc:getDomainsContribution(.)"/>
    <xsl:variable name="domainPrefix" as="xs:string"
      select="rngfunc:getModuleShortName(.)" 
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(.)"
    />
    <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] moduleType="<xsl:sequence select="$moduleType"/>"</xsl:message>
    </xsl:if>
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>
    
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdEnt'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
    />
    
    <xsl:if test="$moduleShortName = 'commonElements'">
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    ELEMENT NAME ENTITIES                      -->
&lt;!-- ============================================================= -->&#x0a;</xsl:text>
      
      <xsl:apply-templates  select="rng:define" mode="element-name-entities" />
      <!-- commonElements.ent includes the element name entities for the metaDecl and tblDecl modules -->
      <xsl:for-each select="$modulesToProcess[rngfunc:getModuleShortName(./*) = ('metaDecl', 'tblDecl')]">
 <xsl:text>
&lt;!-- </xsl:text><xsl:value-of select="str:indent(18)"/><xsl:text>Elements in </xsl:text>
        <xsl:value-of select="str:pad(concat(rngfunc:getModuleShortName(./*), '.mod'), 32)"/><xsl:text>-->
</xsl:text>
        <xsl:apply-templates mode="element-name-entities" select=".//rng:define[rng:element]"/>        
      </xsl:for-each>
    </xsl:if>

    <xsl:if test="$moduleType = 'elementdomain'">
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    ELEMENT EXTENSION ENTITY DECLARATIONS      -->
&lt;!-- ============================================================= -->&#x0a;</xsl:text>
      <xsl:text>&#x0a;</xsl:text>

      <xsl:apply-templates 
        select="/*/rng:define[starts-with(@name, $domainPrefix)]" 
        mode="generate-parment-decl-from-define">
        <xsl:with-param name="indent" as="xs:integer" select="2"/>
      </xsl:apply-templates>
      
    </xsl:if>

    <xsl:if test="$moduleType = 'attributedomain'">
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] entityFile: module is an attribute domain, applying templates in mode generate-parment-decl-from-define...</xsl:message>
        <xsl:message>+ [DEBUG] entityFile: domainPrefix="<xsl:value-of select="$domainPrefix"/>"</xsl:message>
      </xsl:if>
      <xsl:if test="not(/*/rng:define[starts-with(@name, $domainPrefix)])">
        <xsl:message> - [WARN] For attribute domain module, got domain prefix of "<xsl:value-of select="$domainPrefix"/>" but didn't</xsl:message>
        <xsl:message> - [WARN] find any rng:define elements whose @name value starts with that prefix. The define</xsl:message>
        <xsl:message> - [WARN] element for the attribute must be named with the domain prefix, e.g. "<xsl:value-of select="concat($domainPrefix, '-attribute')"/>".</xsl:message>
        <xsl:message> - [WARN] Found the following defines: <xsl:value-of select="string-join(/*/rng:define/@name, ', ')"/></xsl:message>
      </xsl:if>
      <xsl:apply-templates 
        select="/*/rng:define[starts-with(@name, $domainPrefix)]" 
        mode="generate-parment-decl-from-define">
        <xsl:with-param name="indent" as="xs:integer" select="2"/>
      </xsl:apply-templates>
      
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="$moduleShortName = ('topic', 'map')">
        <xsl:text>

&lt;!-- ============================================================= -->
&lt;!--                    ELEMENT NAME ENTITIES                      -->
&lt;!-- ============================================================= -->

        
</xsl:text>
<xsl:apply-templates mode="element-name-entities" select="rng:define"/>
        
        <xsl:text><![CDATA[
<!--                    Also include common elements used in topics
                        and maps                                      -->]]></xsl:text>
        <xsl:text>
&lt;!ENTITY % commonDefns </xsl:text>
<xsl:choose>
  <xsl:when test="$doUsePublicIDsInShell">
    <xsl:text>
  PUBLIC 
                       "-//OASIS//ENTITIES DITA </xsl:text><xsl:value-of select="$ditaVersion"/><xsl:text> Common Elements//EN" 
</xsl:text>
  </xsl:when>
  <xsl:otherwise>
    <xsl:text>
  SYSTEM </xsl:text>
  </xsl:otherwise>
</xsl:choose>                        
                      <xsl:text> "commonElements.ent"                          >
%commonDefns;
          </xsl:text>
      </xsl:when>
      <xsl:otherwise>
          <xsl:if test="ends-with($moduleType, 'domain') or $moduleType = ('topic', 'map')" >
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN ENTITY DECLARATION                  -->
&lt;!-- ============================================================= -->&#x0a;</xsl:text>
            <xsl:apply-templates mode="domainAttContributionEntityDecl"
              select="dita:moduleDesc/dita:moduleMetadata/dita:domainsContribution"
              >
              <xsl:with-param name="domainPrefix" select="$domainPrefix" as="xs:string" />
            </xsl:apply-templates>
        
          </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:text>
&lt;!-- ================ End </xsl:text>
    <xsl:sequence select="$moduleTitle"/>
    <xsl:text> ================== -->&#x0a; </xsl:text>    
  </xsl:template>
  
  <xsl:template match="dita:domainsContribution" mode="domainAttContributionEntityDecl">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="domainPrefix" as="xs:string"/>
    
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

  <xsl:template match="rnga:documentation" mode="entityFile" />

  <xsl:template match="rng:*" priority="-1" mode="entityFile">
    <xsl:message> - [WARN] entityFile: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" /></xsl:message>
  </xsl:template>
    
</xsl:stylesheet>