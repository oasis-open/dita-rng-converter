<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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
  xmlns="http://relaxng.org/ns/structure/1.0"
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc local rng2ditadtd"
  expand-text="yes"
  version="3.0"
  >
  
  <!-- ==========================================================================
       Remove patterns and references to patterns that are set to notAllowed
       
       Any grouping element that would be empty is itself removed.
       
       The filtered result should then reflect only those patterns that are
       allowed.
       ========================================================================== -->
  
  <xsl:template mode="filter-notallowed-patterns" match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatternNames" as="xs:string*" tunnel="yes" select="()"/>
    
    <xsl:if test="$doDebug and false()">
      <xsl:message>+ [DEBUG] filter-notallowed-patterns: notAllowedPatternNames:
{$notAllowedPatternNames => sort() => string-join(',&#x0a;')}        
</xsl:message>
    </xsl:if>
    
    <xsl:document>
      <xsl:apply-templates mode="#current" select="node()">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:document>
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatternNames" as="xs:string*" tunnel="yes" select="()"/>
    
    <xsl:variable name="children" as="node()*">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>      
    </xsl:variable>
    
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      <xsl:choose>
        <xsl:when test="empty($children[. instance of element()])">
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] filter-notallowed-patterns: define "{@name}" has no children after filtering. Setting to empty.</xsl:message>
          </xsl:if>
          <empty/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$children"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
    
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatternNames" as="xs:string*" tunnel="yes" select="()"/>

    <xsl:choose>
      <xsl:when test="@name = $notAllowedPatternNames">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] filter-notallowed-patterns: {name(.)} "{@name}" is not allowed, filtering out.</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:next-match>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="*[rng:notAllowed]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] filter-notallowed-patterns: {name(.)} "{@name}" is not allowed, filtering out.</xsl:message>
    </xsl:if>
    
    <!-- Filter it out. -->
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="rng:choice | rng:zeroOrMore | rng:oneOrMore | rng:optional | rng:group">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:variable name="children" as="node()*">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="exists($children[self::*])">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
          <xsl:sequence select="$children"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>+ [DEBUG] filter-notallowed-patterns: Grouping element {name(..)}/{name(.)} in pattern "{ancestor::rng:define[1]/@name}" has empty children after filtering.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
   
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>      
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="filter-notallowed-patterns" match="@* | text() | processing-instruction() | comment()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
</xsl:stylesheet>