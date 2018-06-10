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
    <xsl:variable name="catalogTree" as="document-node()">
      <xsl:document>
        <xsl:call-template name="expandCatalogFile"/>
      </xsl:document>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>Expand catalog file into temporary tree</xd:desc>
    </xd:doc>
    <xsl:template name="expandCatalogFile">
      <catalog>
        <xsl:apply-templates select="document($catalogUrl)" mode="MODE_EXPAND_CATALOG">
          <xsl:with-param name="prmCatalogDir" tunnel="yes" select="$catalogUrl"/>
        </xsl:apply-templates>
      </catalog>
    </xsl:template>
    
    <xsl:template match="/" mode="MODE_EXPAND_CATALOG">
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="cat:*" mode="MODE_EXPAND_CATALOG"/>
    
    <xsl:template match="cat:catalog" mode="MODE_EXPAND_CATALOG">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="cat:nextCatalog" mode="MODE_EXPAND_CATALOG">
      <xsl:param name="prmCatalogDir" tunnel="yes" as="xs:string"/>
      <xsl:variable name="nextCatalog" as="xs:string" select="string(@catalog)"/>
      <xsl:variable name="fullNextCatalogDir" as="xs:string" select="string(resolve-uri($nextCatalog,$prmCatalogDir))"/>
      <xsl:apply-templates select="document($nextCatalog,.)" mode="#current">
        <xsl:with-param name="prmCatalogDir" tunnel="yes" select="$fullNextCatalogDir"/>
      </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="cat:group" mode="MODE_EXPAND_CATALOG">
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="cat:uri" mode="MODE_EXPAND_CATALOG">
      <xsl:param name="prmCatalogDir" tunnel="yes" as="xs:string"/>
      
      <xsl:variable name="name" select="string(@name)"/>
      <xsl:variable name="uri" select="string(@uri)"/>
      <xsl:variable name="fileUri" select="string(resolve-uri($uri, $prmCatalogDir))"/>
      <uri id="{$name}" uri="{$fileUri}"/>
    </xsl:template>
    
    <xd:doc>
      <xd:desc>Resolve a URI to a URI through the configured catalogs</xd:desc>
      <xd:param>input-uri: URI to be resolved</xd:param>
      <xd:return>File URI. If URI is not mapped, returns input URI.</xd:return>
    </xd:doc>
    <xsl:function name="catutil:resolve-uri" as="xs:string">
        <xsl:param name="input-uri" as="xs:string"/>
      
        <xsl:variable name="resultUri" as="xs:string?" 
          select="string(($catalogTree/catalog/uri[string(@id) eq $input-uri]/@uri)[1])"
        />
        <xsl:choose>
          <xsl:when test="exists($resultUri) and not($resultUri eq '')">
            <xsl:if test="$debug">
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