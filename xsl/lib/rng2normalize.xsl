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
  exclude-result-prefixes="xs xd rng rnga relpath a str ditaarch dita rngfunc rng2ditadtd"
  version="2.0">
  
  <!-- Constructs a normalized version of the root grammar
       with all references expanded.
    -->

  <xsl:template match="/" mode="normalize">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" as="document-node()*" tunnel="yes"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] normalize: Starting...</xsl:message>
    </xsl:if>
    <xsl:variable name="grammarIncludesResolved" as="document-node()">
      <xsl:document>
        <xsl:apply-templates mode="resolveIncludesNormalize">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="origModule" as="document-node()" tunnel="yes" select="."/>
        </xsl:apply-templates>
      </xsl:document>
    </xsl:variable>
    <xsl:variable name="expandedRefs" as="document-node()">
      <xsl:document>
        <xsl:apply-templates select="$grammarIncludesResolved" mode="expandRefs"/>
      </xsl:document>
    </xsl:variable>
    <xsl:sequence select="$expandedRefs"/>
  </xsl:template>
  
  <xsl:template mode="resolveIncludesNormalize expandRefs" match="a:* | dita:*"/>
  
  <xsl:template mode="resolveIncludesNormalize" match="/*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:copy>
      <xsl:attribute name="datatypeLibrary" select="'http://www.w3.org/2001/XMLSchema-datatypes'"/>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="resolveIncludesNormalize" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="resolveIncludesNormalize" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="origModule" as="document-node()" tunnel="yes" select="root(.)"/>
    
    <xsl:variable name="origUri"
      select="if ($origModule/*/@origURI) 
      then $origModule/*/@origURI 
      else string(document-uri($origModule))" as="xs:string"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] resolveIncludesNormalize: rng:include, origUri="<xsl:value-of select="$origUri"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="targetUri" as="xs:string"
      select="string(resolve-uri(@href, $origUri))"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] resolveIncludesNormalize: rng:include, targetUri="<xsl:value-of select="$targetUri"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="rngModule" as="document-node()?" select="document($targetUri)" />
    <xsl:choose>
      <xsl:when test="$rngModule">
        <xsl:apply-templates select="$rngModule/*/*" mode="#current">
          <xsl:with-param name="origModule" as="document-node()" tunnel="yes" select="$rngModule"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [WARN] resolveIncludes: Failed to resolve reference to module "<xsl:value-of select="@href"/>" relative to module "<xsl:value-of select="document-uri($origModule)"/>"</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="resolveIncludesNormalize expandRefs" match="@* | text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="expandRefs" match="/*"> 
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Process each element-defining define once -->
    <xsl:copy>
      <xsl:apply-templates select="@*, rng:define | rng:start" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="expandRefs" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] expandRefs: catch-all: <xsl:value-of select="name(..), '/', name(.)"/></xsl:message>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*,node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="expandRefs" match="rng:start">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="expandRefs" match="rng:define[rng:element]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@*,node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="expandRefs" 
    match="rng:define[ends-with(@name, '.attributes') or
           ends-with(@name, '-atts') or
           ends-with(@name, 'att')]" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] expandRefs: catch-all: <xsl:value-of select="name(..), '/', name(.)"/></xsl:message>
    </xsl:if>
    <xsl:sequence select="."/>
  </xsl:template>

  <xsl:template mode="expandRefs" match="rng:define[count(*) = 1][rng:ref[ends-with(@name, '.element')]]" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] expandRefs: define <xsl:value-of select="@name"/>: with exactly one rng:ref child, </xsl:message>
    </xsl:if>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="expandRefs" match="rng:define"/>
  
  <xsl:template mode="expandRefs" match="rng:ref[not(@name = 'any')]">
    <!-- Patterns with the name "any" are always defined in the shell and are never interesting -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" as="document-node()*" tunnel="yes"/>

    <xsl:variable name="targetName" select="@name" as="xs:string"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] expandRefs: rng:ref: targetName="<xsl:value-of select="$targetName"/>"</xsl:message>
    </xsl:if>
    <!--    <xsl:variable name="target" as="element()*"
      select="$modulesToProcess//*[@name = $targetName][not(self::rng:ref)]"
    />
-->   
    <xsl:variable name="target" as="element()*"
    >
      <xsl:for-each select="$modulesToProcess">
        <xsl:sequence select="key('definesByName', $targetName, .)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="not($target)">
        <xsl:message> - [WARN]   expandRefs: Failed to resolve reference to name "<xsl:value-of select="@name"/>"</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$target/self::rng:element or $target/self::rng:attribute">
            <!-- If the target is an element or attribute, preserve the reference -->
<!--            <xsl:message>+ [DEBUG]   expandRefs: rng:ref: Target is an element or attribute, copying ref.</xsl:message>-->
            <xsl:sequence select="."/>
          </xsl:when>
          <xsl:when test="$target/rng:element">
            <xsl:if test="$doDebug">
              <xsl:message>+ [DEBUG]   expandRefs: rng:ref: Target is an element-defining define, copying ref.</xsl:message>
            </xsl:if>
            <xsl:sequence select="."/>
          </xsl:when>
          <xsl:when test="$targetName = 'any'">
            <xsl:if test="$doDebug">
              <xsl:message>+ [DEBUG]   expandRefs: rng:ref: Target is "any", copying ref.</xsl:message>
            </xsl:if>
            <xsl:sequence select="."/>
          </xsl:when>
          <xsl:otherwise>
            <!-- If it's a define, expand it -->
            <xsl:choose>
              <xsl:when test="ends-with($targetName, '.attributes') or ends-with($targetName, 'attlist')">
                <!-- No need to expand attribute definitions -->
                <xsl:if test="$doDebug">
                  <xsl:message> + [DEBUG]   expandRefs: target is an attribute list definition, copying its content</xsl:message>
                </xsl:if>
                <xsl:sequence select="$target/*"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="$doDebug">
                  <xsl:message> + [DEBUG]   expandRefs: processing children of defines "<xsl:value-of select="$targetName"/>"</xsl:message>
                </xsl:if>
                <xsl:for-each select="$target[not(ends-with(./@name, '.element'))]">
                  <xsl:apply-templates select="./*" mode="#current"/>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>