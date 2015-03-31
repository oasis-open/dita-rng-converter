<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  exclude-result-prefixes="xs xd relpath"
  version="2.0">
  
 <!-- Transform to simply report that given document is or isn't valid 
 
 
      The input to this transform is a document in the root of the directory
      tree containing the documents to be validated (this is so the Ant
      XSLT task can call this transform.
      
      
 -->
  
  <xsl:import href="../lib/relpath_util.xsl"/>
  
  <!-- Set this parameter to limit the generated documents to those
       within a specific subdirectory under the starting directory.
    -->
  <xsl:param name="basedocsSubdir" as="xs:string" select="''"/>
  
  <xsl:output indent="yes"/>

  <xsl:template match="/">
    <xsl:variable name="docUri" as="xs:string" 
      select="string(document-uri(.))"/>
    <xsl:variable name="startingDocsDir" as="xs:string"  
      select="relpath:getParent($docUri)"      
    />
    <xsl:variable name="basedocsDir" as="xs:string"
      select="if ($basedocsSubdir = '') 
      then $startingDocsDir
      else relpath:toUrl(relpath:newFile($startingDocsDir, $basedocsSubdir))"
    />
    <xsl:variable name="collectionUri"
       as="xs:string"
       select="concat($basedocsDir,'?',
             'recurse=yes;',      
             'on-error=warning;',
             'select=*.(dita|ditamap|xml|ditaval);'
            )"
    />
    <xsl:message> + [INFO] Validating documents in collection <xsl:value-of select="$collectionUri"/></xsl:message>
    <xsl:variable name="docs" as="document-node()*" 
      select="collection(iri-to-uri($collectionUri))"/>
    <validation-report>
      <xsl:for-each select="$docs">
        <xsl:sort select="relpath:getName(relpath:getParent(document-uri(.)))"/>
        <xsl:sort select="relpath:getName(document-uri(.))"/>
        <xsl:variable name="pathTokens" select="tokenize(document-uri(.), '/')" as="xs:string*"/>
        <xsl:variable name="last3Tokens" as="xs:string*" select="$pathTokens[position() > last() - 3]"/>
        <document valid="true" uri="{string-join($last3Tokens, '/')}"/><xsl:text>&#x0a;</xsl:text>
      </xsl:for-each>
    </validation-report>
  </xsl:template>
  
</xsl:stylesheet>