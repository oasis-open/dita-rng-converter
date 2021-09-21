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
  version="3.0"  
 >

  <!-- ====================
       Mode class-att-decls
       ==================== -->
  
  <xsl:template match="rng:define[.//rng:attribute[@name='class']]" mode="class-att-decls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- specialization attribute declaration 
    
    <!ATTLIST b           %global-atts;  class CDATA "+ topic/ph hi-d/b "  >

    -->
    <xsl:variable name="tagnameLookupKey" select="@name" as="xs:string"/>
    <xsl:variable name="elementDec" as="element()?" select="key('attlistIndex',$tagnameLookupKey)"/>
    <xsl:variable name="tagname" select="if ($elementDec) then $elementDec/@name else '{unknown}'" as="xs:string?"/>
    <xsl:text>&lt;!ATTLIST  </xsl:text>
    <xsl:value-of select="str:pad($tagname, 12)"/>
    <xsl:if test="$ditaVersion = ('1.2', '1.3')">
      <xsl:text> %global-atts;  </xsl:text>
    </xsl:if>
    <xsl:text> class CDATA </xsl:text>
    <xsl:value-of select="str:pad(concat('&quot;', string(./rng:optional/rng:attribute/@a:defaultValue), '&quot;'), 22)"/>
    <xsl:text>&gt;&#x0a;</xsl:text>
    
  </xsl:template>
  
  <xsl:template match="rng:*" priority="-1" mode="class-att-decls">
    <xsl:message> - [WARN] class-att-decls: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" /><xsl:copy-of select="." /></xsl:message>
  </xsl:template>
  
  
</xsl:stylesheet>