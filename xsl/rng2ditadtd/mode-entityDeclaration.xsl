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
  
  <!-- =====================================================
       Implements the entityDeclaration mode
       
       ===================================================== -->
  
  <xsl:template match="rng:grammar" mode="entityDeclaration">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param 
      name="entityType" 
      as="xs:string" 
      tunnel="yes"
    /><!-- One of "type, "ent", or "mod" 
      
           Note that "type" = "mod" for the purposes of
           constructing filenames because topic and map
           modules use an entity name of *-type.
    -->
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="referencingGrammarUrl" tunnel="yes" as="xs:string"/>
    
    <xsl:variable name="rngShellParent" as="xs:string"
      select="relpath:getParent($referencingGrammarUrl)"
    />
    
    <xsl:variable name="filenameSuffix" as="xs:string"
      select="if ($entityType = 'type') then 'mod' else $entityType"
    />
    <xsl:variable name="entityNameSuffix" as="xs:string"
      select="if ($entityType = 'ent')
      then '-dec'
      else if ($entityType = 'type') then '-type' else '-def'"
    />
    
    <!-- Have to special case the base topic module as its .ent file is named "topicDefn.ent"
         rather than topic.ent.
      -->
    <xsl:variable name="entFilename" as="xs:string"
      select="rngfunc:getEntityFilename(., $filenameSuffix)"
    />
    <xsl:variable name="moduleUrl" as="xs:string"
      select="rngfunc:getGrammarUri(.)"
    />
    <xsl:variable name="relpathFromShell" as="xs:string"
      select="relpath:getParent(relpath:getRelativePath($rngShellParent, $moduleUrl))"
    />
    <xsl:variable name="shortName" as="xs:string"
      select="rngfunc:getModuleShortName(.)"
    />
    <xsl:variable name="pubidTagname" as="xs:string"
      select="concat('dtd', if ($entityType = 'ent') then 'Ent' else 'Mod')"
    />
    <xsl:variable name="publicId" 
      select="rngfunc:getPublicId(., $pubidTagname, true())" 
    />
    <xsl:variable name="entityName" as="xs:string"
      select="concat($shortName, $entityNameSuffix)"
    />
    <!-- FIXME: The replace is a short-term hack to avoid figuring out how to
                generalize the code for getting the result URI for a module
                so we can construct the relative output path properly.
                This hack will work for OASIS files but not necessarily 
                any other organization pattern.
                
                When using public IDs, we only want the entity filename,
                which will almost never be directly resolvable, forcing
                all resolution to go through a catalog or fail. As a 
                matter of code and deployment management, you never want
                a false positive on a failure to resolve through catalogs,
                e.g., the file happens to be locally available in your
                development environment but will not be at the same 
                relative location in any given deployment.
      -->
    <xsl:variable name="entitySystemID" as="xs:string"
      select="
      if ($doUsePublicIDsInShell)
      then $entFilename
      else replace(relpath:newFile($relpathFromShell, $entFilename), '/rng/', '/dtd/')"
    />
    <!-- Special case the topic and map modules, which do not have a *.ent file like all the rest 
         (topic has
         topicDefn.ent, which is included in the topic.mod file. It has to be included *after* 
         all the domain entity integration parameter entities so that those declarations will
         take precedence over those in topicDefn.ent.
      -->
    <xsl:if test="$entityType != 'ent' or 
      ($entityType = 'ent' and 
      not($entityName = 'topic-dec') and 
      not($entityName = 'map-dec'))">    
      <xsl:text>&#x0a;&lt;!ENTITY % </xsl:text><xsl:value-of select="$entityName" /><xsl:text>&#x0a;</xsl:text> 
      <xsl:value-of select="str:indent(2)"/>
      <xsl:choose>
        <xsl:when test="$doUsePublicIDsInShell">
          <xsl:text>PUBLIC "</xsl:text><xsl:value-of select="$publicId" /><xsl:text>"&#x0a;</xsl:text>
          <xsl:value-of select="str:indent(9)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>SYSTEM </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="concat('&quot;', $entitySystemID, '&quot;')"/><xsl:text>&#x0a;</xsl:text>
      <xsl:text>&gt;</xsl:text><xsl:value-of select="concat('%', $entityName, ';')"/><xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>  
  
  <xsl:template match="*" mode="entityDeclaration">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" select="node()" />
  </xsl:template>
  
</xsl:stylesheet>