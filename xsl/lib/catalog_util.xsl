<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  xmlns:catutil="http://local/catalog-utility"
  exclude-result-prefixes="xs xd catutil"
  version="2.0">

  <!-- ===========================================================
       Resolve URIs through OASIS Open entity resolution catalogs
       
       This is the code as provided by Toshihiko Makita with some
       small changes made, mostly to names and comments. No 
       functional change to the templates or functions.
       
       FIXME: Needs the following improvements:
       
       - Use XSLT 3 maps
       - Handle multiple catalog files
       - Generalize URI resolution
       =========================================================== -->
  
  <!-- URI elements by @id -->
  <xsl:key name="catutil:uri-by-id" match="uri" use="@id"/>
  
  <xsl:variable name="catalogTree" as="document-node()">
    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>
    
    <!-- FIXME: This code depends on the global variable $catalogUrl.
      
         It should allow a list of catalog URLs 
      -->
    <xsl:document>
      <xsl:call-template name="expandCatalogFile">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="catalogUrl" as="xs:string?" tunnel="yes" select="$catalogUrl"/>
      </xsl:call-template>
    </xsl:document>
  </xsl:variable>
  
  <xd:doc>
      <xd:desc>Expand catalog file into temporary tree</xd:desc>
  </xd:doc>
  <xsl:template name="expandCatalogFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="catalogUrl" as="xs:string?" tunnel="yes" select="()"/>
    <catalog>
      <xsl:if test="exists($catalogUrl)">
        <xsl:apply-templates select="document($catalogUrl)" mode="MODE_EXPAND_CATALOG">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="catalogUrl" tunnel="yes" select="$catalogUrl"/>
        </xsl:apply-templates>
      </xsl:if>
    </catalog>
  </xsl:template>
  
  <xsl:template match="/" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="*" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cat:*" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
  
  <xsl:template match="cat:catalog" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      <xsl:apply-templates select="*" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cat:nextCatalog" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="catalogUrl" tunnel="yes" as="xs:string?" select="()"/>
    
    <xsl:if test="exists($catalogUrl)">
      <xsl:variable name="nextCatalog" as="xs:string" select="string(@catalog)"/>
      <xsl:variable name="fullNextCatalogDir" as="xs:string" select="string(resolve-uri($nextCatalog,$catalogUrl))"/>
      <xsl:apply-templates select="document($nextCatalog,.)" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="catalogUrl" tunnel="yes" select="$fullNextCatalogDir"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="cat:group" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="*" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="cat:uri" mode="MODE_EXPAND_CATALOG">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="catalogUrl" tunnel="yes" as="xs:string?" select="()"/>
    
    <xsl:variable name="name" select="string(@name)"/>
    <xsl:variable name="uri" select="string(@uri)"/>
    <xsl:variable name="fileUri" select="string(resolve-uri($uri, $catalogUrl))"/>
    <uri id="{$name}" uri="{$fileUri}"/>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>Resolve a URI to a URI through the configured catalogs</xd:desc>
    <xd:param>input-uri: URI to be resolved</xd:param>
    <xd:return>File URI. If URI is not mapped, returns input URI.</xd:return>
  </xd:doc>
  <xsl:function name="catutil:resolve-uri" as="xs:string">
    <xsl:param name="input-uri" as="xs:string"/>
    <xsl:sequence select="catutil:resolve-uri($input-uri, false())"/>
  </xsl:function>

  <xd:doc>
    <xd:desc>Resolve a URI to a URI through the configured catalogs</xd:desc>
    <xd:param name="input-uri">URI to be resolved</xd:param>
    <xd:param name="doDebug">Turn debugging on off</xd:param>
    <xd:return>File URI. If URI is not mapped, returns input URI.</xd:return>
  </xd:doc>
  <xsl:function name="catutil:resolve-uri" as="xs:string">
      <xsl:param name="input-uri" as="xs:string"/>
      <xsl:param name="doDebug" as="xs:boolean"/>
    
      <xsl:variable name="uri-entry" as="element()?"
        select="key('catutil:uri-by-id', $input-uri, $catalogTree)[1]"
      />
      <xsl:variable name="resultUri" as="xs:string?" 
        select="string($uri-entry/@uri)"
      />
      <xsl:choose>
        <xsl:when test="exists($resultUri) and not($resultUri eq '')">
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] catutil:resolve-uri(): URI "<xsl:value-of select="$input-uri"/>" is mapped to "<xsl:value-of select="$resultUri"/>"</xsl:message>
          </xsl:if>
          <xsl:sequence select="$resultUri"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>+ [ERROR] catutil:resolve-uri(): URI "<xsl:value-of select="$input-uri"/>" is not defined in catalog file.</xsl:message>
          <xsl:sequence select="$input-uri"/>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>