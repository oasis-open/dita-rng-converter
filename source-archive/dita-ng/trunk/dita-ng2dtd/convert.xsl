<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
    xmlns:rng="http://relaxng.org/ns/structure/1.0">

    <xsl:output indent="yes"/>
    <xsl:variable name="outputBase">tmp/dtd</xsl:variable>
    <xsl:variable name="uri" select="document-uri(/)"/>
    <xsl:variable name="uriTokens" select="tokenize($uri, '/')"/>
    <xsl:variable name="infotype" select="substring-before($uriTokens[last()], '.')"/>
    <xsl:variable name="module" select="$uriTokens[last()-2]"/>

    <xsl:param name="publicMap" select="'public.xml'"/>
    <xsl:variable name="public" select="document($publicMap)/map"/>

    <xsl:template match="/">
        <xsl:result-document href="{$outputBase}/{$module}/{$infotype}.dtd" method="text">
            <xsl:call-template name="header"/>
            <xsl:call-template name="topicEntityDeclarations"/>
            <xsl:call-template name="domainEntityDeclarations"/>
            <xsl:call-template name="includeModule"/>
            
            <xsl:call-template name="domainElements"/>
            <xsl:call-template name="footer"/>
        </xsl:result-document>

        <xsl:result-document href="{$outputBase}/{$module}/{$infotype}.ent" method="text">
            <xsl:call-template name="entContent"/>
        </xsl:result-document>
        <xsl:result-document href="{$outputBase}/{$module}/{$infotype}.mod" method="text">
            <xsl:call-template name="modContent"/>
        </xsl:result-document>

        
    </xsl:template>

    <xsl:template name="entContent">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    HEADER                                     -->
&lt;!-- ============================================================= -->
&lt;!--  MODULE:    DITA </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text> Entity                               -->
                
                
&lt;!-- ============================================================= -->
&lt;!--                    </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text> ENTITIES                           -->
&lt;!-- ============================================================= -->

&lt;!ENTITY </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>-att     
  "</xsl:text>
        <xsl:value-of
            select="document(concat($infotype, '.mod.rng'), .)//rng:define[@name='domains-atts-value']/rng:value"/>
        <xsl:text>"
>
&lt;!-- ================== End </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text> Entities ===================== -->                
            </xsl:text>
    </xsl:template>
    <xsl:template name="modContent">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    HEADER                                     -->
&lt;!-- ============================================================= -->
&lt;!--  MODULE:    DITA </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>                                      -->
            
&lt;!-- ============================================================= -->
&lt;!--                   ARCHITECTURE ENTITIES                       -->
&lt;!-- ============================================================= -->

&lt;!-- default namespace prefix for DITAArchVersion attribute can be
     overridden through predefinition in the document type shell   -->
&lt;!ENTITY % DITAArchNSPrefix
  "ditaarch"
>

&lt;!-- must be instanced on each topic type                          -->
&lt;!ENTITY % arch-atts 
             "xmlns:%DITAArchNSPrefix; 
                        CDATA
                                  #FIXED 'http://dita.oasis-open.org/architecture/2005/'
              %DITAArchNSPrefix;:DITAArchVersion
                        CDATA
                                  '1.2'
"
>

            
            
            
        </xsl:text>
    </xsl:template>
    <xsl:template name="header">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    HEADER                                     -->
&lt;!-- ============================================================= -->
&lt;!--  MODULE:    DITA </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text> DTD                                  -->          
        </xsl:text>


    </xsl:template>
    <xsl:template name="footer">
        <xsl:text>
&lt;!-- ================== End DITA Concept DTD  ==================== -->
            </xsl:text>
    </xsl:template>
    
    <xsl:template name="topicEntityDeclarations">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    TOPIC ENTITY DECLARATIONS                  -->
&lt;!-- ============================================================= -->

&lt;!ENTITY % </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>-dec     
  PUBLIC "</xsl:text>
        <xsl:value-of select="$public/entities[@infotype=$infotype]/@public"/>
        <xsl:text>" 
         "</xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>.ent"
>%</xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>-dec;            
        </xsl:text>
    </xsl:template>
    
    <xsl:template name="domainEntityDeclarations">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN ENTITY DECLARATIONS                 -->
&lt;!-- ============================================================= -->
        </xsl:text>
        <!-- entity declarations for domains -->
        <xsl:for-each select="//rng:include[ends-with(@href, 'Domain.mod.rng')]">
            <xsl:variable name="domainValue" select="document(@href)/rng:grammar/rng:define[@name='domains-atts-value']/rng:value"/>
            <xsl:variable name="domain" select="substring-before(tokenize($domainValue, ' ')[last()], ')')"/>
            <xsl:variable name="uriTokens" select="tokenize(resolve-uri(@href, document-uri(/)), '/')"/>
            <xsl:variable name="module" select="$uriTokens[last()-2]"/>
            <xsl:variable name="domainFile" select="substring-before($uriTokens[last()], '.')"/>
            
            
            <xsl:text>
&lt;!ENTITY % </xsl:text>
            <xsl:value-of select="$domain"/>
            <xsl:text>-dec     
  PUBLIC "</xsl:text>
            <xsl:value-of select="$public/entities[@domain=$domain]/@public"/>
            <xsl:text>"
    "../../</xsl:text>
            <xsl:value-of select="$module"/>
            <xsl:text>/dtd/</xsl:text>
            <xsl:value-of select="$domainFile"/>
            <xsl:text>.ent"
>%</xsl:text>
            <xsl:value-of select="$domain"/>
            <xsl:text>-dec;            
        </xsl:text>
        </xsl:for-each>        
    </xsl:template>
    
    
    <xsl:template name="domainElements">
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN ELEMENT INTEGRATION                 -->
&lt;!-- ============================================================= -->
        </xsl:text>
        <!-- domain elements -->
        <xsl:for-each select="//rng:include[ends-with(@href, 'Domain.mod.rng')]">
            <xsl:variable name="domainValue" select="document(@href)/rng:grammar/rng:define[@name='domains-atts-value']/rng:value"/>
            <xsl:variable name="domain" select="substring-before(tokenize($domainValue, ' ')[last()], ')')"/>
            <xsl:variable name="uriTokens" select="tokenize(resolve-uri(@href, document-uri(/)), '/')"/>
            <xsl:variable name="module" select="$uriTokens[last()-2]"/>
            <xsl:variable name="domainFile" select="substring-before($uriTokens[last()], '.')"/>
            
            
            <xsl:text>
&lt;!ENTITY % </xsl:text>
            <xsl:value-of select="$domain"/>
            <xsl:text>-def     
  PUBLIC "</xsl:text>
            <xsl:value-of select="$public/elements[@domain=$domain]/@public"/>
            <xsl:text>"
    "../../</xsl:text>
            <xsl:value-of select="$module"/>
            <xsl:text>/dtd/</xsl:text>
            <xsl:value-of select="$domainFile"/>
            <xsl:text>.mod"
>%</xsl:text>
            <xsl:value-of select="$domain"/>
            <xsl:text>-def;            
        </xsl:text>
        </xsl:for-each>        
    </xsl:template>
    
    
    <xsl:template name="includeModule">
        <xsl:text>
&lt;!--                    Embed </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text> to get specific elements     -->
&lt;!ENTITY % </xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>-typemod 
                        PUBLIC 
"</xsl:text>
        <xsl:value-of select="$public/elements[@infotype=$infotype]/@public"/>
        <xsl:text>" 
"</xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>.mod">
%</xsl:text>
        <xsl:value-of select="$infotype"/>
        <xsl:text>-typemod;
        </xsl:text>
    </xsl:template>

</xsl:stylesheet>
