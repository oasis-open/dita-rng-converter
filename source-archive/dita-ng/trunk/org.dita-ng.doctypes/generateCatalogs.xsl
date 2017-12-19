<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog"
    xpath-default-namespace="http://relaxng.org/ns/structure/1.0"
    exclude-result-prefixes="xd xs"
    version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 2, 2011</xd:p>
            <xd:p><xd:b>Author:</xd:b> george</xd:p>
            <xd:p>Generates an XML Catalog</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:variable name="baseID" select="substring(base-uri(document('')), 1, 
        max(index-of(string-to-codepoints(base-uri(document(''))), string-to-codepoints('/'))))"/>
    
    <xsl:template name="main">
        <xsl:result-document href="catalog-rng.xml">
            <xsl:text xml:space="preserve">
</xsl:text>
            <xsl:comment>XML Catalog for DITA-NG Relax NG XML schemas</xsl:comment>
            <xsl:text>&#10;</xsl:text>
            <catalog>
                    <xsl:apply-templates select="collection('./rng?select=*.rng;recurse=yes;on-error=ignore')"/>
            </catalog>
        </xsl:result-document>
        <xsl:result-document href="catalog-rnc.xml">
            <xsl:text xml:space="preserve">
</xsl:text>
            <xsl:comment>XML Catalog for DITA-NG Relax NG compact schemas</xsl:comment>
            <xsl:text>&#10;</xsl:text>
            <catalog>
                <xsl:apply-templates select="collection('./rng?select=*.rng;recurse=yes;on-error=ignore')" mode="compact"/>
            </catalog>
        </xsl:result-document>
        <xsl:text>&#10;</xsl:text>
        <xsl:comment>XML Catalog for DITA-NG Relax NG schemas</xsl:comment>
        <xsl:text>&#10;</xsl:text>
        <catalog>
            <xsl:text>&#10;  </xsl:text>
            <nextCatalog catalog="catalog-rng.xml"/>
            <xsl:text>&#10;  </xsl:text>
            <nextCatalog catalog="catalog-rnc.xml"/>
            <xsl:text>&#10;</xsl:text>
        </catalog>
    </xsl:template>
    <xsl:template match="/">
        <xsl:variable name="uri" select="substring-after(base-uri(.), $baseID)"/>
        <xsl:if test="./comment()[contains(., 'urn:')]">
            <xsl:text>&#10;  </xsl:text>
            <xsl:text>&#10;  </xsl:text>
            <xsl:comment>
                <xsl:text> Add mapping for: </xsl:text>
                <xsl:value-of select="$uri"/>
            </xsl:comment>
            <!-- extract the urn: values -->    
            <xsl:variable name="data" select="comment()[contains(., 'urn:')]" as="xs:string"/>

            <xsl:analyze-string select="$data" regex="urn:.*\.rng(:\d+(\.\d+)?)?">
                <xsl:matching-substring>
                    <xsl:text>&#10;  </xsl:text>
                    <system systemId="{.}" uri="{$uri}"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="/" mode="compact">
        <xsl:variable name="uri" select="substring-after(base-uri(.), $baseID)"/>
        <xsl:if test="./comment()[contains(., 'urn:')]">
            <xsl:text>&#10;  </xsl:text>
            <xsl:text>&#10;  </xsl:text>
            <xsl:comment>
                <xsl:text> Add mapping for: </xsl:text>
                <xsl:value-of select="replace($uri, 'rng', 'rnc')"/>
            </xsl:comment>
            <!-- extract the urn: values -->    
            <xsl:variable name="data" select="comment()[contains(., 'urn:')]" as="xs:string"/>
            
            <xsl:analyze-string select="$data" regex="urn:.*\.rng(:\d+(\.\d+)?)?">
                <xsl:matching-substring>
                    <xsl:text>&#10;  </xsl:text>
                    <system systemId="{replace(., 'rng', 'rnc')}" uri="{replace($uri, 'rng', 'rnc')}"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>