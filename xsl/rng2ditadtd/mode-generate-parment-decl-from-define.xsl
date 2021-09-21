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
     Mode generate-parment-decl-from-define
     
     Produces parameter entity declarations for element type and
     attribute lists.
     ================================================================ -->
  
  <xsl:template mode="generate-parment-decl-from-define" match="rng:define[@name = 'arch-atts']" priority="10">
    <!-- arch-atts declaration is hard-coded -->
  </xsl:template>
  
  <xsl:template mode="generate-parment-decl-from-define" match="rng:define[rng:notAllowed]" priority="15">
    <!-- Ignore not-allowed defines -->
  </xsl:template>
  
  <xsl:template mode="generate-parment-decl-from-define"
    match="rng:define[ends-with(@name,'info-types')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" select="14"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-parment-decl-from-define: info-types define: "{@name}"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="rng:empty | rng:notAllowed">
        <xsl:text>&lt;!ENTITY % </xsl:text>
        <xsl:value-of select="@name" />
        <xsl:text>&#x0a;</xsl:text>
        <xsl:value-of select="str:indent($indent)"/>        
        <xsl:text>&quot;no-topic-nesting&quot;</xsl:text>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:text>&gt;&#x0a;</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:next-match>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="generate-parment-decl-from-define" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="indent" as="xs:integer" select="14"/>
    <xsl:param name="nlBeforeClosingQuote" as="xs:boolean" select="false()"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-parment-decl-from-define: rng:define name="{@name}"</xsl:message>
    </xsl:if>
    
    <!-- FIXME: The following is a hack that depends on a consistent naming convention
         for attribute sets.
         
         The more complete solution I think requires producing a single-document resolved
         grammar (e.g., RNG simplification) and then examining the define in that 
         grammar to see if it has any attribute declarations.
      -->
    <xsl:variable name="isAttSet" as="xs:boolean"
      select="matches(@name, '-atts|attribute|\.att') or .//rng:attribute"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-parment-decl-from-define: name="{@name}"</xsl:message>
      <xsl:message>+ [DEBUG]   generate-parment-decl-from-define: isAttSet="{$isAttSet}"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="addparen" as="xs:boolean"
      select="not($isAttSet) and (count(rng:*) &gt; 1 or rng:text)"/>
    
    <xsl:text>&lt;!ENTITY % {@name}&#x0a;</xsl:text>
    <xsl:text>{str:indent($indent)}&quot;</xsl:text>
    <xsl:if test="$addparen">
      <xsl:text>(</xsl:text>
    </xsl:if>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-parment-decl-from-define: define, name="{@name}" - Applying templates in mode element-decls</xsl:message>
    </xsl:if>


    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] Constructing effective pattern for define "{@name}"...</xsl:message>
    </xsl:if>
    
    <!-- Apply any notAlloweds to determine the effective pattern.
      
         If the effective pattern contains no groups then the pattern is an empty
         pattern and we have to report that and handle it in some way.
         
      -->
    <xsl:variable name="effectivePattern" as="element(rng:define)">
      <xsl:apply-templates mode="construct-effective-pattern" select=".">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>  
    </xsl:variable>
    
    <xsl:variable name="isPatternEmpty" as="xs:boolean"
      select="empty($effectivePattern/rng:*)"
    />
    
    <xsl:if test="$isPatternEmpty">
      <xsl:message>- [WARN] Pattern "{@name}" is empty after removing notAllowed patterns.</xsl:message>
    </xsl:if>
    
    <xsl:variable name="doShowEffectivePattern" as="xs:boolean" 
      select="
        $isPatternEmpty or
        @name = ('') or 
        $doDebug
      "
    />
    
    <xsl:if test="$doShowEffectivePattern">
      <xsl:message>+ [DEBUG]   base pattern for define "{@name}" ({base-uri(.)}):
        
<xsl:sequence select="rngfunc:report-element(.)"/></xsl:message>
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG]   notAllowed pattern names:" {$notAllowedPatternNames => string-join(', ')}</xsl:message>
      </xsl:if>
      
      <xsl:message>+ [DEBUG]   effective pattern for define "{@name}" ({base-uri(.)}):
        
<xsl:sequence select="rngfunc:report-element($effectivePattern)"/></xsl:message>
    </xsl:if>
    
    <xsl:apply-templates mode="element-decls">
      <xsl:with-param name="indent" 
        select="if ($addparen) then $indent + 2 else $indent + 1" 
        as="xs:integer" 
        tunnel="yes"
      />
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="isAttSet" as="xs:boolean" select="$isAttSet" tunnel="yes"/>
      <xsl:with-param name="tagname" tunnel="yes" as="xs:string"   select="@name"/>     
    </xsl:apply-templates>
    <!-- Special case for @longdescre on object element: -->
    <xsl:if test="@name = 'object.attributes'">
      <xsl:text>&#x0a;{str:indent($indent + 1)}longdescre CDATA     #IMPLIED</xsl:text>
    </xsl:if>
    <xsl:if test="$addparen">
      <xsl:text>)</xsl:text>
    </xsl:if>
    <!-- Handle case of bare <text> in a define -->
    <xsl:if test="count(rng:*) = 1 and rng:text">
      <xsl:text>*</xsl:text>
    </xsl:if>
    <xsl:if test="$nlBeforeClosingQuote">
      <xsl:text>&#x0a;{str:indent(2)}</xsl:text>
    </xsl:if>
    <xsl:text>&quot;</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:text>&gt;&#x0a;</xsl:text>
  </xsl:template>
  
</xsl:stylesheet>