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
  
<!-- ===================================================================
     Mode header-content
     
     =================================================================== -->
  
  
  <xsl:template match="dita:moduleDesc" mode="header-comment">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="dita:headerComment" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="dita:headerComment" mode="header-comment">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Note that the header comment is a single string with
         space preserved.
      -->
    <xsl:choose>
      <xsl:when test="$headerCommentStyle = 'comment-per-line'">
        <xsl:analyze-string select="." regex="^.+$" flags="m">
          <xsl:matching-substring>
            <xsl:text>&lt;!-- </xsl:text>
            <xsl:value-of select="str:pad(., 61)"/>
            <xsl:text> -->&#x0a;</xsl:text>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of select="if (normalize-space(.) != '') then concat('&lt;-- ', ., ' -->') else ''"/>             
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&lt;!-- </xsl:text>
        <!-- FIXME: Escape anything that needs escaping -->
        <xsl:value-of select="string(.)"/>
        <xsl:text> -->&#x0a;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
</xsl:stylesheet>