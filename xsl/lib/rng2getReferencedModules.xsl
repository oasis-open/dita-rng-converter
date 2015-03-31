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
  version="2.0">
  <!-- =========================
       Mode getReferencedModules
       ========================= -->
  
  <xsl:template match="rng:grammar" mode="getReferencedModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="rng:include | rng:div" mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="rng:include" mode="getReferencedModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="origModule" as="document-node()" tunnel="yes" select="root(.)"/>
    <xsl:param name="modulesToProcess" as="document-node()*" tunnel="yes"/>
    <xsl:param name="isProcessNestedIncludes" as="xs:boolean" tunnel="yes" select="true()"/>

    <xsl:variable name="rngModule" as="document-node()?" select="document(@href, $origModule)" />
    <xsl:if test="$doDebug">    
      <xsl:message> + [DEBUG] getReferencedModules: rng:include: document-uri($rngModule)="<xsl:value-of select="document-uri($rngModule)"/>"</xsl:message>
    </xsl:if>    
    <xsl:choose>
      <xsl:when test="$rngModule">
        <xsl:variable name="gatheredModule" 
          select="$modulesToProcess[local:isSameModule(string(/*/@origURI),
               string(document-uri($rngModule)))][1]" as="document-node()?"
        />
        <xsl:choose>
          <xsl:when test="$gatheredModule">
            <xsl:if test="$doDebug">
              <xsl:message> + [DEBUG] getReferencedModules: Found referenced module <xsl:value-of select="$gatheredModule/*/@origURI"/></xsl:message>
            </xsl:if>
            <xsl:sequence select="$gatheredModule"/>
            <xsl:if test="$isProcessNestedIncludes">           
              <xsl:apply-templates select="$gatheredModule/*" mode="#current">
                <xsl:with-param name="origModule" select="$rngModule" as="document-node()" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="moduleUri" select="string(document-uri($rngModule))" as="xs:string"/>
            <xsl:choose>
              <xsl:when test="ends-with($moduleUri, 'Mod.rng')">
                <xsl:message> - [ERROR] getReferencedModules: Failed to find gathered module for referenced module "<xsl:value-of select="$moduleUri"/>"</xsl:message>
              </xsl:when>
              <xsl:otherwise>
                <!-- Not a DITA module, ignore it -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [WARN] getReferencedModules: Failed to resolve reference to module for href "<xsl:value-of select="@href"/> relative to URI "<xsl:value-of select="document-uri($origModule)"/>".</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- ======================
       getIncludedModules
       
       Simply resolves includes without 
       comparing to previously-gathered modules.
       ====================== -->
  
  <xsl:template mode="getIncludedModules" match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="getIncludedModules" match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select=".//rng:include" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="getIncludedModules" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:variable name="rngModule" as="document-node()?" select="document(@href, .)" />
    <xsl:sequence select="$rngModule"/>
    <xsl:apply-templates select="$rngModule" mode="#current"/>
  </xsl:template>
  
  <xsl:function name="local:isSameModule" as="xs:boolean">
    <xsl:param name="uri1" as="xs:string"/>
    <xsl:param name="uri2" as="xs:string"/>
    
    <!-- Compare 2 URIs to see if they are equivalent.
         If they are both URNs or both not URNs, they must be identical.
         If one is a URN and one is a URL, then compare the last token.
         If both tokens end with ".rng" then the last tokens must be identical.
         If one does not end with .rng then the name parts must be identical.
         
         This depends on the URN convention that the last token of the 
         URN is either the RNG filename or the filename part of the RNG filename.
         
         This is a bit of a hack but I can't think of a more reliable way
         to do this with the current processing code as structured, because there's
         no easy way to correlate the original URI used on the rng:include
         element with the URL of the actual document.
      -->
    <xsl:variable name="result" as="xs:boolean">
      <xsl:choose>
        <xsl:when test="
          (starts-with($uri1, 'urn:') and starts-with($uri2, 'urn:')) or
          (not(starts-with($uri1, 'urn:')) and not(starts-with($uri2, 'urn:')))">
          <xsl:sequence select="$uri1 = $uri2"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="lastToken1" as="xs:string"
            select="(if (starts-with($uri1, 'urn:')) 
                        then tokenize($uri1, ':')
                        else tokenize($uri1, '/'))[last()]"
          />
          <xsl:variable name="lastToken2" as="xs:string"
            select="(if (starts-with($uri2, 'urn:')) 
                        then tokenize($uri2, ':')
                        else tokenize($uri2, '/'))[last()]"
          />

          <xsl:choose>
            <xsl:when test="ends-with($lastToken1,'.rng') and 
                            ends-with($lastToken2, '.rng')">
              <xsl:sequence select="$lastToken1 = $lastToken2"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="filename1" as="xs:string"
                select="relpath:getNamePart($lastToken1)"/>
              <xsl:variable name="filename2" as="xs:string"
                select="relpath:getNamePart($lastToken2)"/>
              <xsl:sequence select="$filename1 = $filename2"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$result"/>
  </xsl:function>
</xsl:stylesheet>