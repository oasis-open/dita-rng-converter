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
  version="3.0">
  <!-- =========================
       Mode getReferencedModules
       ========================= -->
  
  <xsl:template match="rng:grammar" mode="getReferencedModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getReferencedModules: rng:grammar - applying templates to rng:include and rng:div elements...</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="rng:include | rng:div" mode="#current" >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    </xsl:apply-templates>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getReferencedModules: rng:grammar - Done applying templates to rng:include and rng:div elements...</xsl:message>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:include" mode="getReferencedModules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- FIXME: Won't need this once xml:base is set on root elements of intermediate docs. -->
    <xsl:param name="origModule" as="document-node()" tunnel="yes" select="root(.)"/>
    <xsl:param name="modulesToProcess" as="document-node()*" tunnel="yes"/>
    <xsl:param name="isProcessNestedIncludes" as="xs:boolean" tunnel="yes" select="true()"/>

    <xsl:variable name="rngModule" as="document-node()?" select="document(@href, $origModule)" />
    <xsl:if test="$doDebug">    
      <xsl:message> + [DEBUG] getReferencedModules: rng:include: document-uri($rngModule)="{document-uri($rngModule)}" ("{base-uri($rngModule/*)}")</xsl:message>
    </xsl:if>    
    <xsl:choose>
      <xsl:when test="$rngModule">
        <!-- FIXME: Determine if we should be using document-uri() or base-uri() here, probably base-uri -->
        <xsl:variable name="gatheredModule" 
          select="
            $modulesToProcess[
              local:isSameModule(
                  string(base-uri(/*)),
                  string(base-uri($rngModule)))
            ][1]" as="document-node()?"
        />
        <xsl:choose>
          <xsl:when test="$gatheredModule">
            <xsl:if test="$doDebug">
              <xsl:message> + [DEBUG] getReferencedModules: Found referenced module {$gatheredModule/*/@origURI}</xsl:message>
            </xsl:if>
            <xsl:sequence select="$gatheredModule"/>
            <xsl:if test="$isProcessNestedIncludes">           
              <xsl:apply-templates select="$gatheredModule/*" mode="#current">
                <!-- FIXME: Won't need this once xml:base is set on root elements of intermediate docs. -->
                <xsl:with-param name="origModule" select="$rngModule" as="document-node()" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <!-- FIXME: Determine if we should be using document-uri() or base-uri() here. -->
            <xsl:variable name="moduleUri" select="string(document-uri($rngModule))" as="xs:string"/>
            <xsl:choose>
              <xsl:when test="ends-with($moduleUri, 'Mod.rng')">
                <xsl:message> - [ERROR] getReferencedModules: Failed to find gathered module for referenced module "{$moduleUri}"</xsl:message>
              </xsl:when>
              <xsl:otherwise>
                <!-- Not a DITA module, ignore it -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [WARN] getReferencedModules: Failed to resolve reference to module for href "{@href} relative to URI "{document-uri($origModule)}" ("{base-uri($origModule/*)}").</xsl:message>
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
  
  <!-- FIXME: This is a refactor of a much more complex function that is no longer necessary
       because the code now uses base-uri(), not document-uri().
       
       Leaving the function to maintain the knowledge of the URI comparison semantic.
    -->
  <xsl:function name="local:isSameModule" as="xs:boolean">
    <xsl:param name="uri1" as="xs:string"/>
    <xsl:param name="uri2" as="xs:string"/>
    
    <xsl:variable name="result" select="$uri1 eq $uri2"/>
    <xsl:sequence select="$result"/>
  </xsl:function>
</xsl:stylesheet>