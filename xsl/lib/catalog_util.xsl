<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:cat="urn:oasis:names:tc:entity:xmlns:xml:catalog"
    xmlns:catu="http://local/catalog-utility"
    exclude-result-prefixes="xs xd"
    version="2.0">

    <xd:doc>
        <xd:desc>DITA-OT Catalog file tree</xd:desc>
    </xd:doc>
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
        <xsl:variable name="fileUri" select="string(resolve-uri($uri,$prmCatalogDir))"/>
        <uri id="{$name}" uri="{$fileUri}"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Get file URI from URN using catalog file tree</xd:desc>
        <xd:param>$prmUrn: URN</xd:param>
        <xd:return>File URI</xd:return>
    </xd:doc>
    <xsl:function name="catu:getFileUriFromUrn" as="xs:string">
        <xsl:param name="prmUrn" as="xs:string"/>
        <xsl:variable name="fileUri" as="xs:string" select="string(($catalogTree/catalog/uri[string(@id) eq $prmUrn]/@uri)[1])"/>
        <xsl:choose>
            <xsl:when test="$fileUri ne ''">
                <xsl:if test="$debug">
                    <xsl:message> + [DEBUG] URN="<xsl:value-of select="$prmUrn"/>" is mapped to "<xsl:value-of select="$fileUri"/>"</xsl:message>
                </xsl:if>
                <xsl:sequence select="$fileUri"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message> + [ERROR] URN="<xsl:value-of select="$prmUrn"/>" is not defined in catalog file.</xsl:message>
                <xsl:sequence select="$prmUrn"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
</xsl:stylesheet>