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
  <!--======================================
      Mode make-element-type-name-parments
      ====================================== -->
  
  <xsl:template mode="make-element-type-name-parments" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] make-element-type-name-parments: rng:define: name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    
    <xsl:apply-templates select=".//rng:ref" mode="make-element-type-name-parments">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="make-element-type-name-parments" match="rng:ref">
    <xsl:text>&lt;!ENTITY % </xsl:text><xsl:value-of select="str:pad(@name, 48)"/>
    <xsl:text>"</xsl:text><xsl:value-of select="@name"/><xsl:text>">&#x0a;</xsl:text>
    
  </xsl:template>
  
  
</xsl:stylesheet>