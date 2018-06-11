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
  xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog"
  version="3.0">
  
  <!-- ========================================================
       Generate OASIS XML entity resolution catalogs for
       things generated from the RNG modules (or for the RNG
       modules themselves).
       ======================================================== -->
  
  <xsl:param name="includeGenerationComment" as="xs:string" select="'no'"/>
  
  <xsl:variable name="doGenerationComment" as="xs:boolean" 
    select="matches($includeGenerationComment, 'yes|true|on|1', 'i')"/>
  
  <xsl:output name="xml-catalog"
    method="xml"
    indent="yes"
  />
  
  <xsl:template name="generateCatalog">
    <!-- Takes a set of RNG documents and generates an XML entity resolution
         catalog for each of the modules for which module metadata is
         present and for which the required public ID or URN is
         specified.
      -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="rngDocs" as="document-node()*"/>
    <xsl:param name="catalogUri" as="xs:string">
      <!-- The URI of the result catalog -->
    </xsl:param>
    <xsl:param name="catalogType" as="xs:string" select="'all'">
      <!-- The catalogType parameter specifies the type of catlaog
           to be produced:
           
           - 'all' : Entries for each type of schema are included
           - 'dtd' : Only DTD entries
           - 'rng' : Only RNG entries
           - 'rnc' : Only RNC entries
           - 'schema' : The XSDs that use URNs to reference modules
           - 'schema-url' : The XSDs that use URls to reference modules
           
        -->
    </xsl:param>
    
    <xsl:message> + [INFO]   catalogType="<xsl:value-of select="$catalogType"/>"...</xsl:message>
    
    <xsl:variable name="schemaTypes" as="xs:string*"
      select="if ($catalogType = 'all') 
      then ('dtd', 'rnc', 'rng', 'schema', 'schema-url')
      else ($catalogType)"
    />
    <!-- Generate the top-level catalog, which has a reference to each schema-type-specific catalog
      
         We only do this for catalog type "all".
      -->
    <xsl:choose>
      <xsl:when test="$catalogType = 'all'">
        <xsl:message> + [INFO]   <xsl:value-of select="$catalogUri"/></xsl:message>
        <xsl:result-document href="{$catalogUri}" format="xml-catalog">
          <catalog>
            <xsl:for-each select="$schemaTypes">
              <nextCatalog catalog="{.}/catalog.xml"/>
            </xsl:for-each>
          </catalog>
        </xsl:result-document>
      </xsl:when>
    </xsl:choose>
    
    
    <!-- Generate the schema-type-specific catalogs, which each have a reference to the catalogs for
         each package:
      -->
    <xsl:for-each select="$schemaTypes">
      <xsl:variable name="uri" as="xs:string"
        select="relpath:newFile(relpath:newFile(relpath:getParent($catalogUri), .), 'catalog.xml')"
      />
      <xsl:message> + [INFO]   <xsl:value-of select="$uri"/></xsl:message>
      <xsl:result-document href="{$uri}" 
        format="xml-catalog">
        <catalog>
          <xsl:if test="$doGenerationComment">
            <xsl:call-template name="makeGenerationComment"/>        
          </xsl:if>
          <xsl:for-each-group select="$rngDocs[/*/dita:moduleDesc]" group-by="rngfunc:getModulePackage(.)">
            <xsl:sort select="rngfunc:getModulePackage(.)"/>
            <xsl:if test="$doDebug">
              <xsl:message> + [DEBUG] Package "<xsl:value-of select="current-grouping-key()"/>"</xsl:message>
            </xsl:if>
            <nextCatalog catalog="{current-grouping-key()}/catalog.xml"/>
          </xsl:for-each-group>     
        </catalog>
      </xsl:result-document>
      
      <!-- Now for each catalog type, generate the per-package catalogs: -->
      
      <xsl:call-template name="makePackageCatalogs">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="rngDocs" as="document-node()*" select="$rngDocs"/>
        <xsl:with-param name="schemaType" as="xs:string" select="."/>
        <xsl:with-param name="schemaTypeDir" as="xs:string" 
          select="relpath:newFile(relpath:getParent($catalogUri), .)"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:message> + [INFO] generateCatalog(): Catalogs generated.</xsl:message>
  </xsl:template>
  
  <xsl:template name="makePackageCatalogs">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="rngDocs" as="document-node()*"/>
    <xsl:param name="schemaType" as="xs:string"/>
    <xsl:param name="schemaTypeDir" as="xs:string">
      <!-- The directory for the current schema type -->
    </xsl:param>
        
    <xsl:for-each-group select="$rngDocs[/*/dita:moduleDesc]" group-by="rngfunc:getModulePackage(.)">
      <xsl:sort select="rngfunc:getModulePackage(.)"/>
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] Package "<xsl:value-of select="current-grouping-key()"/>"</xsl:message>
      </xsl:if>
      <xsl:call-template name="makePackageCatalog">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="rngDocs" as="document-node()*" select="current-group()"/>
        <xsl:with-param name="schemaType" as="xs:string" select="$schemaType"/>
        <xsl:with-param name="packageName" as="xs:string" select="current-grouping-key()"/>
        <xsl:with-param name="parentDir" as="xs:string" 
          select="relpath:newFile($schemaTypeDir, current-grouping-key())"/>
      </xsl:call-template>
    </xsl:for-each-group>     
  </xsl:template>
  
  <xsl:template name="makePackageCatalog">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="rngDocs" as="document-node()*"/>
    <xsl:param name="schemaType" as="xs:string"/>
    <xsl:param name="parentDir" as="xs:string">
      <!-- The directory for the current schema type -->
    </xsl:param>
    <xsl:param name="packageName" as="xs:string"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] makePackageCatalog: packageName="<xsl:value-of select="$packageName"/>"</xsl:message>
      <xsl:message> + [DEBUG]   makePackageCatalog: schemaType="<xsl:value-of select="$schemaType"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="rngDocsSorted" as="document-node()*">
      <xsl:for-each select="$rngDocs">
        <xsl:sort select="relpath:getName(.)"/>
        <xsl:sequence select="."/>
      </xsl:for-each>
    </xsl:variable>
    
    <!-- NOTE: These catalogs are in the xxx/base directory.
               The modules will be under the schema-specific directory
               under this directory.
      -->
    <xsl:variable name="catalogUri" as="xs:string"
      select="relpath:newFile($parentDir, 'catalog.xml')"
    />
    <xsl:message> + [INFO]   <xsl:value-of select="$catalogUri"/></xsl:message>
    <xsl:result-document href="{$catalogUri}" format="xml-catalog">
      <catalog>
        <xsl:if test="$doGenerationComment">
          <xsl:call-template name="makeGenerationComment"/>
        </xsl:if>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:comment> <xsl:value-of select="rngfunc:getModuleTitle(./*)"/> </xsl:comment>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:choose>
          <xsl:when test="$schemaType = 'dtd'">
            <xsl:apply-templates mode="generate-catalogs"
              select="$rngDocsSorted/*/dita:moduleDesc"
              >
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="catalogType" as="xs:string" tunnel="yes" select="$schemaType"/>
              <xsl:with-param name="entryType" as="xs:string" tunnel="yes" select="'public'"/>
            </xsl:apply-templates>
            <xsl:call-template name="additionalEntries">
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="catalogType" as="xs:string" tunnel="yes" select="$schemaType"/>
              <xsl:with-param name="entryType" as="xs:string" tunnel="yes" select="'urn'"/>
              <xsl:with-param name="packageName" as="xs:string" select="$packageName"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
          <group><xsl:comment> System ID (URL) catalog entries </xsl:comment>
            <xsl:apply-templates mode="generate-catalogs"
              select="$rngDocsSorted/*/dita:moduleDesc" 
              >
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="catalogType" as="xs:string" tunnel="yes" select="$schemaType"/>
              <xsl:with-param name="entryType" as="xs:string" tunnel="yes" select="'system'"/>
            </xsl:apply-templates>
          </group>
            <group><xsl:comment> Public ID (URN) catalog entries </xsl:comment>
              <xsl:apply-templates mode="generate-catalogs"
                select="$rngDocsSorted/*/dita:moduleDesc"
                >
                <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
                <xsl:with-param name="catalogType" as="xs:string" tunnel="yes" select="$schemaType"/>
              <xsl:with-param name="entryType" as="xs:string" tunnel="yes" select="'urn'"/>
            </xsl:apply-templates>
            <xsl:call-template name="additionalEntries">
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="catalogType" as="xs:string" tunnel="yes" select="$schemaType"/>
              <xsl:with-param name="entryType" as="xs:string" tunnel="yes" select="'urn'"/>
              <xsl:with-param name="packageName" as="xs:string" select="$packageName"/>
            </xsl:call-template>
          </group>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#x0a;</xsl:text>
      </catalog>
    </xsl:result-document>
  
  </xsl:template>
  
  <xsl:template name="additionalEntries">
    <xsl:param name="doDebug" as="xs:boolean" select="false()" tunnel="yes"/>
    <xsl:param name="catalogType" as="xs:string" tunnel="yes"/>
    <xsl:param name="entryType" as="xs:string" tunnel="yes"/>
    <xsl:param name="packageName" as="xs:string"/>
    <!-- Generate additional entries as required for specific catalog types
         or catalogs.
      -->

    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] additionalEntries: packageName="<xsl:value-of select="$packageName"/>"</xsl:message>
      <xsl:message> + [DEBUG] additionalEntries:   catalogType="<xsl:value-of select="$catalogType"/>"</xsl:message>
      <xsl:message> + [DEBUG] additionalEntries:   entryType="<xsl:value-of select="$entryType"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$packageName = 'base' and $entryType = 'urn' and $catalogType = 'schema'">
        <!-- For the schema URN catalog, need entries for the ditaarch.xsd, xml.xsd schemas,
             and ditabaseMod.xsd, which are not generated from anything in the RNG grammars.
          -->
        <system systemId="ditaarch.xsd" uri="xsd/ditaarch.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:ditaarch.xsd" uri="xsd/ditaarch.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:xml.xsd:1.x" uri="xsd/xml.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:ditaarch.xsd:{$ditaVersion}" uri="xsd/ditaarch.xsd"/>
        
        <system systemId="xml.xsd" uri="xsd/xml.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:xml.xsd" uri="xsd/xml.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:xml.xsd:1.x" uri="xsd/xml.xsd"/>
        <system systemId="urn:oasis:names:tc:dita:xsd:xml.xsd:{$ditaVersion}" uri="xsd/xml.xsd"/>
        
      </xsl:when>
      <xsl:when test="$packageName = 'technicalContent' and $entryType = 'urn' and $catalogType = 'schema'">
        <system systemId="ditabaseMod.xsd" uri="ditabaseMod.xsd" />
        <system systemId="urn:oasis:names:tc:dita:xsd:ditabaseMod.xsd" uri="xsd/ditabaseMod.xsd" />
        <system systemId="urn:oasis:names:tc:dita:xsd:ditabaseMod.xsd:1.x" uri="xsd/ditabaseMod.xsd" />
        <system systemId="urn:oasis:names:tc:dita:xsd:ditabaseMod.xsd:1.2" uri="xsd/ditabaseMod.xsd" />
        
      </xsl:when>
      <xsl:when test="$ditaVersion = '1.3' and 
                      $packageName = 'technicalContent' and 
                      $catalogType = 'dtd'">
        <!-- This entry reflects the value used in the mathmlDomainMod.rng file.
             FIXME: Should be possible to generate these entries from the
             rng:externalref elements in modules.
          -->
        <public publicId="-//OASIS//ELEMENTS DITA 1.3 Mathml3 Driver//EN"
          uri="dtd/mathml/mathml3-ditadriver.dtd"
        />
        <!-- This public ID is statically defined in the mathml3-ditadriver.dtd file: -->
        <public publicId="-//OASIS//ELEMENTS DITA 1.3 MathML 3//EN" 
          uri="dtd/mathml/mathml3/mathml3.dtd"
        />   
        <!-- This entry reflects the value used in the svgDomainMod.rng file.
             FIXME: Should be possible to generate these entries from the
             rng:externalref elements in modules.
          -->
        <public publicId="-//OASIS//ELEMENTS DITA 1.3 SVG 1.1 Driver//EN"
          uri="dtd/svg/svg11-ditadriver.dtd"
        />
        <!-- This public ID is statically defined in the svg11-ditadriver.dtd file: -->
        <public publicId="-//OASIS//ELEMENTS DITA 1.3 SVG 1.1//EN" 
          uri="dtd/svg/svg11/svg11-flat-20110816.dtd"
        />   
      </xsl:when>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template name="makeGenerationComment">
    <xsl:text>&#x0a;</xsl:text>
    <xsl:comment> Catalog generated by rng2generateCatalogs.xsl at <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01] [H01]:[m01]:[s01] [z]')"/><xsl:text> </xsl:text> </xsl:comment>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs" match="dita:moduleDesc">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current"
      select="dita:moduleMetadata/dita:shellPublicIds | 
      dita:moduleMetadata/dita:modulePublicIds"
    >
      <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs" 
    match="dita:modulePublicIds | 
           dita:shellPublicIds"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="catalogType" as="xs:string" tunnel="yes"/>

    <xsl:choose>
      <xsl:when test="$catalogType = 'all'">
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$catalogType = 'dtd'">
        <xsl:apply-templates mode="#current" select="dita:dtdMod | dita:dtdEnt | dita:dtdShell">
          <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$catalogType = 'rng'">
        <xsl:apply-templates mode="#current" select="dita:rngMod | dita:rngShell">
          <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$catalogType = 'rnc'">
        <xsl:apply-templates mode="#current" select="dita:rncMod | dita:rncShell">
          <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$catalogType = ('schema', 'schema-url')">
        <!-- The catalogs for the schema and schema-url forms of the XSDs are the same -->
        <xsl:apply-templates mode="#current" select="dita:xsdMod | dita:xsdGrp | dita:xsdShell">
          <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [ERROR] generate-catalogs: Unrecognized catalogType value "<xsl:value-of select="$catalogType"/></xsl:message>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>
  
  <xsl:template mode="generate-catalogs"
    match="dita:dtdMod | 
           dita:dtdEnt | 
           dita:dtdShell">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="publicIdVars"> 
      <xsl:apply-templates mode="expand-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="publicId1x" as="xs:string"
      select="replace($publicIdVars, '([:\s])1\.[1-3]', '$11.x')"
    />
    <xsl:variable name="publicIdNoVars">
      <xsl:apply-templates mode="ignore-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    <!-- FIXME: Determine if we should be using document-uri() or base-uri() here. -->
    <xsl:variable name="initialBaseName" as="xs:string"
      select="relpath:getNamePart(document-uri(root(.)))"
    />
    <!-- DTD .mod and .ent files don't include the "Mod" ending that the RNG files have. -->
    <xsl:variable name="baseName" as="xs:string"
      select="if (ends-with($initialBaseName, 'Mod')) 
       then substring-before($initialBaseName, 'Mod') 
       else $initialBaseName"
    />
    <xsl:variable name="ext" as="xs:string"
      select="
      if (self::dita:dtdMod) 
         then 'mod' 
         else 
           if (self::dita:dtdEnt) 
              then 'ent' 
              else 'dtd'"
    />
    <xsl:variable name="systemId" as="xs:string"
      select="concat('dtd', '/', $baseName, '.', $ext)"
    />
    <public publicId="{normalize-space($publicIdNoVars)}" uri="{normalize-space($systemId)}"/>
    <public publicId="{normalize-space($publicId1x)}" uri="{normalize-space($systemId)}"/>
    <public publicId="{normalize-space($publicIdVars)}" uri="{normalize-space($systemId)}"/>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs"
    match="dita:xsdMod | 
           dita:xsdGrp | 
           dita:xsdShell"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:call-template name="handleXsdEntries">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug" />
      <xsl:with-param name="ext" select="'xsd'" as="xs:string"/>
      <xsl:with-param name="dirName" select="'xsd'" as="xs:string"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs"
    match="dita:rngMod | 
           dita:rngShell"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:call-template name="handleRncRngEntries">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug" />
      <xsl:with-param name="ext" select="'rng'" as="xs:string"/>
      <xsl:with-param name="dirName" select="'rng'" as="xs:string"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs"
    match="dita:rncMod | 
           dita:rncShell"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:call-template name="handleRncRngEntries">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug" />
      <xsl:with-param name="ext" select="'rnc'" as="xs:string"/>
      <xsl:with-param name="dirName" select="'rnc'" as="xs:string"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="handleRncRngEntries">  
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="ext" as="xs:string"/>
    <xsl:param name="dirName" as="xs:string"/>
    <xsl:param name="entryType" as="xs:string" tunnel="yes">
      <!-- Entry type is one of 'urn', 'system', or 'all' -->
    </xsl:param>
    <xsl:variable name="urnVars">
      <xsl:apply-templates mode="expand-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="urn1x" as="xs:string"
      select="replace($urnVars, ':1\.[1-3]', ':1.x')"
    />
    <xsl:variable name="urnNoVars">
      <xsl:apply-templates mode="ignore-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    <!-- FIXME: Determine if we should be using document-uri() or base-uri() here. -->
    <xsl:variable name="baseName" as="xs:string"
      select="relpath:getNamePart(document-uri(root(.)))"
    />
    <xsl:variable name="systemId" as="xs:string"
      select="concat($dirName, '/', $baseName, '.', $ext)"
    />
    
    <!-- Because of bugs in the Apache parser, which incorrectly resolves
         XSD schemalocations using the DTD external parsed entity code
         path, we have to generate both system and uri entries in the catalog
         so that all catalog processors will work.
         
         But in theory we should only need uri entries for things that 
         aren't external parameter entities.
      -->
      <xsl:if test="$entryType = ('system', 'all')">        
        <system systemId="{normalize-space($urnNoVars)}" uri="{normalize-space($systemId)}"/>
        <system systemId="{normalize-space($urn1x)}" uri="{normalize-space($systemId)}"/>
        <system systemId="{normalize-space($urnVars)}" uri="{normalize-space($systemId)}"/>
      </xsl:if>
      <xsl:if test="$entryType = ('urn', 'all')">
        <uri name="{normalize-space($urnNoVars)}" uri="{normalize-space($systemId)}"/>
        <uri name="{normalize-space($urn1x)}" uri="{normalize-space($systemId)}"/>
        <uri name="{normalize-space($urnVars)}" uri="{normalize-space($systemId)}"/>
      </xsl:if>
  </xsl:template>
  
  <xsl:template name="handleXsdEntries">  
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="ext" as="xs:string"/>
    <xsl:param name="dirName" as="xs:string"/>
    <xsl:param name="entryType" as="xs:string" tunnel="yes">
      <!-- Entry type is one of 'urn', 'system', or 'all' -->
    </xsl:param>
    
    <!-- For XSDs there may be both *Mod.xsd and *Grp.xsd files so we need
         to handle both forms.
         
         The context element for this template will be either dita:xsdGrp or dita:xsdMod
      -->
    
    <xsl:variable name="urnVars">
      <xsl:apply-templates mode="expand-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="urn1x" as="xs:string"
      select="replace($urnVars, ':1\.[1-3]', ':1.x')"
    />
    <xsl:variable name="urnNoVars">
      <xsl:apply-templates mode="ignore-variables">
        <xsl:with-param name="doDebug" as="xs:boolean" select="$doDebug" tunnel="yes"/>        
      </xsl:apply-templates>
    </xsl:variable>
    
    <!-- FIXME: Determine if we should be using document-uri() or base-uri() here. -->
    <xsl:variable name="moduleName" as="xs:string"
      select="relpath:getNamePart(document-uri(root(.)))"
    />
    <!-- NOTE: This function handles the special case of commonElement* XSD files. -->
    <xsl:variable name="baseName" as="xs:string"
      select="rngfunc:getXsdModuleBaseFilename($moduleName)"
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(ancestor::rng:grammar)"
    />
    <xsl:variable name="xsdModuleType" as="xs:string"
      select="if (self::dita:xsdGrp) 
                 then 'Grp' 
                 else ''"
    />
    <!-- This is all a bit of a hack to handle the vagaries of XSD file naming -->
    <xsl:variable name="fileName" as="xs:string"
      select="if ($xsdModuleType = 'Grp')
                 then if (ends-with($baseName, 'Mod'))
                         then concat(substring-before($baseName, 'Mod'), $xsdModuleType)
                         else concat($baseName, $moduleType)
                 else $baseName"
    />
    <xsl:variable name="systemId" as="xs:string"
      select="concat($dirName, '/', $fileName, '.', $ext)"
    />
    
    <!-- Because of bugs in the Apache parser, which incorrectly resolves
         XSD schemalocations using the DTD external parsed entity code
         path, we have to generate both system and uri entries in the catalog
         so that all catalog processors will work.
         
         But in theory we should only need uri entries for things that 
         aren't external parameter entities.
      -->
    <xsl:if test="$entryType = ('system', 'all')">        
      <system systemId="{normalize-space($urnNoVars)}" uri="{normalize-space($systemId)}"/>
      <system systemId="{normalize-space($urn1x)}" uri="{normalize-space($systemId)}"/>
      <system systemId="{normalize-space($urnVars)}" uri="{normalize-space($systemId)}"/>
    </xsl:if>
    <xsl:if test="$entryType = ('urn', 'all')">
      <uri name="{normalize-space($urnNoVars)}" uri="{normalize-space($systemId)}"/>
      <uri name="{normalize-space($urn1x)}" uri="{normalize-space($systemId)}"/>
      <uri name="{normalize-space($urnVars)}" uri="{normalize-space($systemId)}"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="ignore-variables" match="dita:var">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
  
  <xsl:template mode="expand-variables" match="dita:var">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="name" select="@name" as="xs:string"/>
    <xsl:variable name="isRecognizedName" as="xs:boolean"
      select="$name = ('ditaver')"
    />
    <xsl:choose>
      <xsl:when test="$isRecognizedName">
        <xsl:if test="@presep">
          <xsl:value-of select="@presep"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$name = 'ditaver'">
            <xsl:value-of select="$ditaVersion"/>
          </xsl:when>
        </xsl:choose>
        <xsl:if test="@postsep">
          <xsl:value-of select="@postsep"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> - [WARN] dita:var: Unrecognized @name value "<xsl:value-of select="$name"/>"</xsl:message>
        <xsl:value-of select="concat('${', @name, '}')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="expand-variables ignore-variables" match="text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
  
  <xsl:template mode="generate-catalogs" match="text()" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>
  
</xsl:stylesheet>