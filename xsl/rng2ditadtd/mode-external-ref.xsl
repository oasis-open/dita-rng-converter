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
  
  <!-- ====================================================================
       Mode external-ref
       
       RNG external references are to grammars that are treated as 
       separate grammars, meaning that the external grammar's patterns
       are not combined with the referencing grammar's patterns.
       
       DITA uses these for non-DITA grammars like SVG and MathML.
       ==================================================================== -->
  
  <xsl:template mode="externalRef" match="rng:externalRef">
    <!-- Expect to find the attributes dita:dtdPublicId (optional)
         and dita:dtdSystemId (required).
      -->
    
    <xsl:variable name="dtdPublicId" as="xs:string?"
      select="@dita:dtdPublicId"
    />
    <xsl:variable name="dtdSystemId" as="xs:string?"
      select="@dita:dtdSystemId"
    />
    <xsl:if test="not($dtdSystemId)">
      <xsl:message> - [ERROR] No @dita:dtdSystemId specified for rng:externalRef href="<xsl:value-of select="@href"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="entityName" as="xs:string"
      select="relpath:getNamePart(relpath:getName($dtdSystemId))"
    />
    <xsl:variable name="externalIds">
      <xsl:choose>
        <xsl:when test="$dtdPublicId">
          <xsl:text>   PUBLIC "</xsl:text><xsl:value-of select="$dtdPublicId"/><xsl:text>"&#x0a;</xsl:text>
          <xsl:text>          "</xsl:text><xsl:value-of select="$dtdSystemId"/><xsl:text>"&#x0a;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>   SYSTEM "</xsl:text><xsl:value-of select="$dtdSystemId"/><xsl:text>"&#x0a;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>
&lt;!ENTITY % </xsl:text><xsl:value-of select="$entityName"/><xsl:text>&#x0a;</xsl:text>
    <xsl:value-of select="$externalIds"/>
    <xsl:text>&gt;</xsl:text><xsl:value-of select="concat('%', $entityName, ';', '&#x0a;')"/>
  </xsl:template>
  
</xsl:stylesheet>