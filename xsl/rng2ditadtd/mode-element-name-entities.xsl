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
  version="2.0"  >
   
  <!-- ================================================================
       Mode element-name-entities
       
       ================================================================ -->
  
  <xsl:template mode="element-name-entities" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-name-entities: rng:define: name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="#current" select="rng:element"/>
  </xsl:template>
  
  <xsl:template mode="element-name-entities" match="rng:element">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] element-name-entities: rng:element: name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <!-- Generate an element name entity declaration 
    
    <!ENTITY % b           "b"                                           >

    -->
    <xsl:variable name="tagname" select="string(@name)" as="xs:string"/>    
    <xsl:text>&lt;!ENTITY % </xsl:text>
    <xsl:variable name="paddedName" as="xs:string"
      select="str:pad($tagname, 12)"
    />
    <xsl:value-of select="$paddedName"/>
    <xsl:if test="not(ends-with($paddedName, ' '))">
      <xsl:text>&#x0a;</xsl:text>
      <xsl:value-of select="str:indent(23)"/>
    </xsl:if>    
    <xsl:value-of select="str:pad(concat('&quot;', $tagname, '&quot;'), 46)"/>
    <xsl:text>&gt;&#x0a;</xsl:text>    
  </xsl:template>

  <xsl:template match="rng:*" priority="-1" mode="element-name-entities">
    <xsl:message> - [WARN] element-name-entities: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" /><xsl:copy-of select="." /></xsl:message>
  </xsl:template>
    
</xsl:stylesheet>