<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditadtd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc rng2ditadtd"
  version="3.0">
  <!-- ==============================
       Gather Modules mode
       
       This mode takes as input shell documents and resolves
       all the includes to construct the set of referenced
       modules.      
       ============================== -->

  <xsl:template match="rng:grammar" mode="gatherModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select=".//rng:include" mode="#current" />
  </xsl:template>

  <xsl:template match="rng:include" mode="gatherModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="rngModule" as="document-node()?" select="document(@href, .)" />
    <xsl:choose>
      <xsl:when test="$rngModule">
        <xsl:if test="false() and $doDebug">
<!--          <xsl:message> + [DEBUG] gatherModules: Resolved reference to module <xsl:sequence select="string(@href)" /></xsl:message>-->
<!--          <xsl:message> + [DEBUG]   document-uri($rngModule)="<xsl:value-of select="document-uri($rngModule)"/>"</xsl:message>-->
        </xsl:if>
        <xsl:sequence select="$rngModule"/>
        <xsl:apply-templates mode="gatherModules" select="$rngModule"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [ERROR] Failed to resolve reference to module <xsl:sequence select="string(@href)" /> relative to base "<xsl:sequence select="document-uri(.)"/>" ("<xsl:value-of select="base-uri(./*)"/>")</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>