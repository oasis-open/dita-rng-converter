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
  
  <!-- ==============================================================
       Standalone RNG-to-entity resolution catalog generation
       transform.
       
       This transform generates catalogs for each of the different
       document schema types (DTD, XSD, RNG, RNC) as a standalone
       operation. It uses the same base logic as used by the 
       schema-type-specific generation scripts.
       
       NOTE: This transform does not use any input document specified
       on the command line. It is intended to be used by directly
       specifying the template to run (e.g., the Saxon -t parameter),
       but if given a document it will simply call the main template.
       
       There is no direct output of this transform, only result documents
       for each catalog.
       
       Copyright (c) 2014 OASIS Open
       ============================================================== -->
  
  <xsl:include href="../lib/relpath_util.xsl" />
  <xsl:include href="../lib/catalog_util.xsl" />
  <xsl:include href="../lib/rng2functions.xsl"/>
  <xsl:include href="../lib/rng2gatherModules.xsl"/>
  <xsl:include href="../lib/rng2generateCatalogs.xsl"/>
  
  <xsl:param name="outdir" as="xs:string" select="''"/>
  <!-- Output directory to put the generated DTD module files in.
       If not specified is the same as the output directory.
       This allows you to have shell DTDs go to one location and
       modules to another.
    -->
  <xsl:param name="ditaVersion" as="xs:string"
    select="'1.2'"
  />
  
  <xsl:param name="debug" as="xs:string" select="'false'"/>
  <xsl:variable name="doDebug" as="xs:boolean" 
    select="matches($debug, 'true|yes|on|1', 'i')" 
  />
  
  <xsl:param name="rootDir" as="xs:string" required="no"/>
  
  <xsl:param name="catalogType" as="xs:string" select="'all'"/>
  <!-- The catalogType parameter specifies the type of catlaog
       to be produced:
       
       - 'all' : Entries for each type of schema are included
       - 'dtd' : Only DTD entries
       - 'rng' : Only RNG entries
       - 'rnc' : Only RNC entries
       - 'schema' : The XSDs that use URNs to reference modules
       - 'schema-url' : The XSDs that use URls to reference modules
       
    -->
  
  <xd:doc>
    <xd:param>$catalogUrl: File URL of [DITA-OT]/catalog-dita.xml</xd:param>
  </xd:doc>
  
  <!-- FIXME: This is used by the catalog utility to resolve URIs through a catalog.
              
              This needs to be replaced with a list of catalogs
              and then used to construct a global map representing
              the resolved catalogs to be used for URI lookup.
    -->
  <xsl:param name="catalogUrl" as="xs:string?" select="()"/>
  
  <xsl:output omit-xml-declaration="yes"/>
  
  <xsl:template name="processDir">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    <!-- Template to process a directory tree. The "rootDir" parameter must
         be set, either the parent dir of the source document or explicitly
         specified as a runtime parameter.
      -->
    <xsl:call-template name="reportParameters"/>
    
    <xsl:message> + [INFO] Preparing documents to process...</xsl:message>
    <xsl:variable name="effectiveRootDir" as="xs:string" 
      select="if ($rootDir != '')
      then $rootDir
      else relpath:getParent(document-uri(root(.)))
      "/>
    <xsl:message> + [INFO] processDir: effectiveRootDir="<xsl:value-of select="$effectiveRootDir"/></xsl:message>
    <xsl:variable name="collectionUri" 
      select="concat($effectiveRootDir, '?', 
      'recurse=yes;',
      'select=*.rng'
      )" 
      as="xs:string"/>
    <xsl:variable name="rngDocs" as="document-node()*"
      select="collection(iri-to-uri($collectionUri))"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Documents to process:</xsl:message>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:for-each select="$rngDocs">
        <xsl:message> + [DEBUG]  <xsl:value-of 
          select="substring-after(string(document-uri(.)), concat($effectiveRootDir, '/'))"/></xsl:message>
      </xsl:for-each>
      <xsl:message> + [DEBUG]</xsl:message>
    </xsl:if>    
        
    <xsl:message> + [INFO] Generating Catalogs...</xsl:message>
    
    <xsl:call-template name="generateCatalog">
      <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
      <xsl:with-param name="rngDocs" select="$rngDocs" as="document-node()*"/>
      <xsl:with-param name="catalogType" select="$catalogType" as="xs:string"/>
      <xsl:with-param name="catalogUri" as="xs:string"
        select="relpath:toUrl(relpath:newFile($outdir, 'catalog.xml'))"
      />
    </xsl:call-template>
    
    <xsl:message> + [INFO] Done.</xsl:message>
  </xsl:template>
  
  <xsl:template name="reportParameters">
    <xsl:message> + [INFO] Parameters:
      
      debug              ="<xsl:value-of select="$debug"/>"
      ditaVersion        ="<xsl:value-of select="$ditaVersion"/>"
      outdir             ="<xsl:value-of select="$outdir"/>"
      rootDir            ="<xsl:value-of select="$rootDir"/>"
      
    </xsl:message>    
    
    
  </xsl:template>
  
</xsl:stylesheet>