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
  
  <!-- ====================================================
       Mode generate-attlist-decl
       
       Generates attribute list declarations.
       ==================================================== -->
  
  <xsl:template mode="generate-attlist-decl" match="rng:ref[ends-with(@name, '.attlist')]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="define" as="element()?" 
      select="key('definesByName', @name)[1]"
    />
    <xsl:if test="count($define) = 0">
      <xsl:message> - [WARN] No rng:define element for referenced name "{@name}".</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="$define/rng:ref" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="generate-attlist-decl" match="rng:ref[ends-with(@name, '.attributes')]">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="tagname" tunnel="yes" as="xs:string"/>
    
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(root(.)/*)"
    />
    
    <xsl:text>&lt;!ATTLIST  </xsl:text>
    <xsl:value-of select="$tagname" />
    <xsl:text> </xsl:text>
    <xsl:value-of select="concat('%', @name, ';')"/>
    <xsl:if test="rngfunc:getModuleType(ancestor-or-self::rng:grammar) = ('topic', 'map') and
      $moduleShortName = $tagname
      ">
      <xsl:text>
                 %arch-atts;
                 domains 
                        CDATA
                                  "&amp;included-domains;"&#x0a;</xsl:text>      
    </xsl:if>
    <xsl:text>&gt;&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template mode="generate-attlist-decl" match="rng:ref" priority="-1">
    
  </xsl:template>
  
  
  
</xsl:stylesheet>