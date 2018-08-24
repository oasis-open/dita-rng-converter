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
  exclude-result-prefixes="xs xd rng rnga relpath a str ditaarch dita rngfunc rng2ditadtd"
  expand-text="yes"
  version="3.0">
  
  <!-- Does preprocessing on the RNG documents to remove <div> elements.
    -->
  
  <xsl:template match="/" mode="removeDivs">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
<!--    <xsl:message> + [DEBUG] removeDivs: /, document-uri(.)=<xsl:value-of select="document-uri(.)"/></xsl:message>-->
    <xsl:document>
      <xsl:apply-templates mode="#current"/>
    </xsl:document>
  </xsl:template>
  
  <xsl:template mode="removeDivs" match="rng:grammar" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:variable name="base-uri" select="string(base-uri(.))" as="xs:string"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] removeDivs: rng:grammar, base-uri="{$base-uri}"</xsl:message>
    </xsl:if>
    <xsl:copy>
      <xsl:attribute name="xml:base" select="$base-uri"/>
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="removeDivs" match="*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:copy>
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="@*|text()|processing-instruction()|comment()" mode="removeDivs">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="removeDivs" match="rng:div" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" select="node()"/>
  </xsl:template>
  
</xsl:stylesheet>