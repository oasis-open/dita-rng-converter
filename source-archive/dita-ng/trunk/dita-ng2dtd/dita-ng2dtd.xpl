<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
    xmlns:p="http://www.w3.org/ns/xproc" 
    xmlns:c="http://www.w3.org/ns/xproc-step" 
    version="1.0" 
    name="ConvertDITANG2DTD">
    <p:input    port="source" />
    <p:output   port="result" />
    <p:serialization port="result" media-type="text/plain" method="text" />

    <p:variable name="input" select="document-uri(.)" />
    <p:variable name="base" select="'/Users/george/Documents/workspace/dita-ng/dita-ng2dtd/'" />

    <!-- Invoke the simplification process -->
    <p:exec name="simplifyRNG" encoding="UTF-8" omit-xml-declaration="false" command="java">
        <p:with-option name="args" select="concat('-jar ', $base, '../lib/jing.jar -s ', $input)" />
    </p:exec>

    <!-- Unwrap the c:result element -->
    <p:filter name="simplifiedRNG" select="/*/*[1]" />

    <!-- Fix the simplified grammar -->
    <p:xslt name="fixedSimplifiedRNG">
        <p:input port="stylesheet">
            <p:inline>
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace="http://relaxng.org/ns/structure/1.0" exclude-result-prefixes="xs" version="2.0">
                    <xsl:template match="node() | @*">
                        <xsl:copy>
                            <xsl:apply-templates select="node() | @*" />
                        </xsl:copy>
                    </xsl:template>
                    <xsl:template match="oneOrMore[choice/text]">
                        <zeroOrMore xmlns="http://relaxng.org/ns/structure/1.0">
                            <xsl:apply-templates select="node() | @*" />
                        </zeroOrMore>
                    </xsl:template>
                    <xsl:template match="define[@name='_1']">
                        <define name="_1" xmlns="http://relaxng.org/ns/structure/1.0">
                            <element name="ANY">
                                <zeroOrMore>
                                    <ref name="_1" />
                                </zeroOrMore>
                            </element>
                        </define>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
        <p:input port="parameters">
            <p:empty />
        </p:input>
    </p:xslt>

    <!-- We need to store this to be able to apply Trang -->
    <p:group>
        <p:store    href="tmp/tmp.rng" />
        <p:load     href="tmp/tmp.rng" />
    </p:group>

    <!-- Convert with Trang -->
    <p:exec name="convertToDTD" command="java" result-is-xml="false">
        <p:with-option name="args" select="concat('-jar ', $base, '../lib/trang.jar -I rng -O dtd ',  $base, 'tmp/tmp.rng ',  $base, 'tmp/tmp.dtd')" />
        <p:input port="source">
            <p:empty />
        </p:input>
    </p:exec>

    <p:xslt name="defaults">
        <p:input port="source">
            <p:pipe port="source" step="ConvertDITANG2DTD" />
        </p:input>
        <p:input port="stylesheet">
            <p:inline>
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0" exclude-result-prefixes="#all" version="2.0">

                    <xsl:template match="/">
                        <defaults>
                            <xsl:apply-templates mode="collect" />
                        </defaults>
                    </xsl:template>
                    <xsl:template match="rng:include" mode="collect">
                        <xsl:apply-templates select="document(@href)/*" mode="collect" />
                    </xsl:template>
                    <xsl:template match="rng:attribute[@a:defaultValue][@name='domains']" mode="collect">
                        <xsl:variable name="element" select="substring-before(//rng:start/rng:ref[1]/@name, '.')" />
                        <xsl:text>&lt;!ATTLIST </xsl:text>
                        <xsl:value-of select="$element" />
                        <xsl:text> domains CDATA "</xsl:text>
                        <xsl:value-of select="@a:defaultValue" />
                        <xsl:text>">
</xsl:text>
                    </xsl:template>
                    <xsl:template match="rng:attribute[@a:defaultValue][@name='class']" mode="collect">
                        <xsl:variable name="element" select="substring-before(ancestor::rng:define/@name, '.')" />
                        <xsl:text>&lt;!ATTLIST </xsl:text>
                        <xsl:value-of select="$element" />
                        <xsl:text> class CDATA "</xsl:text>
                        <xsl:value-of select="@a:defaultValue" />
                        <xsl:text>">
</xsl:text>
                    </xsl:template>
                    <xsl:template match="text()" mode="collect" />
                </xsl:stylesheet>

            </p:inline>
        </p:input>
        <p:input port="parameters">
            <p:empty />
        </p:input>
    </p:xslt>

    <!-- Fix the DTD for the ditaarch namespace and wildcards -->
    <p:xslt>

        <p:with-param name="defaults" select="/defaults" port="parameters">
            <p:pipe port="result" step="defaults" />
        </p:with-param>
        <p:input port="source">
            <p:pipe port="result" step="convertToDTD" />
        </p:input>

        <p:input port="stylesheet">
            <p:inline>
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
                    <xsl:param name="defaults" />
                    <xsl:template match="/">
                        <xsl:variable name="dtd" select="unparsed-text('tmp/tmp.dtd')" />
                        <xsl:variable name="dtd1" select="replace($dtd, 
                            'xmlns:ns1', 
                            'xmlns:ditaarch')" />
                        <xsl:variable name="dtd2" select="replace($dtd1, 
                            'ns1:DITAArchVersion CDATA #IMPLIED', 
                            'ditaarch:DITAArchVersion CDATA ''1.2''')" />
                        <xsl:variable name="dtd3" select="replace($dtd2, 
                            '&lt;!ELEMENT ANY \(ANY\)\*>', 
                            '')" />
                        <xsl:variable name="dtd4" select="replace($dtd3, 
                            '&lt;!ELEMENT (.*?) \(.*?(\n(.*?))?(\n(.*?))?\|ANY\)\*>', 
                            '&lt;!ELEMENT $1 ANY>')" />
                        <!-- remove class attributes -->
                        <xsl:variable name="dtd5" select="replace($dtd4, 
                            '  class CDATA #IMPLIED', 
                            '')" />
                        <xsl:variable name="dtd6" select="replace($dtd5, 
                            '  domains CDATA #IMPLIED', 
                            '')" />
                        <dtd>
                            <xsl:value-of select="$dtd6" />
                            <xsl:text>
</xsl:text>
                            <xsl:value-of select="$defaults" />
                        </dtd>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
    </p:xslt>
</p:declare-step>
