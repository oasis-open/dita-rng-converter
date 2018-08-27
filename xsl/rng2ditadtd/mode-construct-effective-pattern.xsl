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
  expand-text="yes"
  version="3.0"  >  
  <!-- ================================================================
       Mode construct-effective-patterns
       
       Takes a pattern and a set of notAllowed patterns and produces
       a new pattern with all notAllowed patterns removed.
       ================================================================ -->
  
  <xsl:template mode="construct-effective-pattern" as="element(rng:define)" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] construct-effective-pattern: Processing define "{@name}"
  <xsl:sequence select="rngfunc:report-element(.)"/>      
      </xsl:message>
    </xsl:if>
    
    <xsl:copy>
      <xsl:attribute name="xml:base" select="base-uri(.)"/>
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>

    <xsl:choose>
      <xsl:when test="@name = $notAllowedPatternNames">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] construct-effective-pattern: rng:ref, name="{@name}" - Referenced pattern is notAllowed, ignoring.</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="rng:zeroOrMore | rng:oneOrMore | rng:optional | rng:group | rng:choice">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
        
    <xsl:variable name="contents" as="element()*">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="empty($contents)">
        <xsl:if test="$doDebug">
          <xsl:message>- [DEBUG] construct-effective-pattern: {name(.)} in define {ancestor::rng:define[1]/@name} empty after removing notAllowed patterns.</xsl:message>
          <xsl:message>- [DEBUG]     Original markup:
<xsl:sequence select="rngfunc:report-element(.)"></xsl:sequence>            
          </xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates mode="#current" select="@*"/>
          <xsl:sequence select="$contents"/>            
        </xsl:copy>  
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] construct-effective-pattern: {name(..)}/{name(.)}: <xsl:sequence select="."/></xsl:message>
    </xsl:if>
    
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="processing-instruction() | comment()" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Ignore -->
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] construct-effective-pattern: {name(..)}/text(): "{.}"</xsl:message>
    </xsl:if>
    
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="construct-effective-pattern" match="@*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:sequence select="."/>
  </xsl:template>
</xsl:stylesheet>