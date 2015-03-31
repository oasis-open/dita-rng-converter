<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditaxsd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  exclude-result-prefixes="xs xd rng rnga relpath str rngfunc local rng2ditaxsd"
  version="2.0">
  
  <xsl:include href="../lib/relpath_util.xsl" />
  <xsl:include href="../lib/rng2functions.xsl"/>
  <xsl:include href="../lib/rng2gatherModules.xsl"/>
  <xsl:include href="../lib/rng2generateCatalogs.xsl"/>
  <xsl:include href="../lib/rng2removeDivs.xsl"/>
  <xsl:include href="../lib/rng2normalize.xsl"/>
  <xsl:include href="../lib/rng2getReferencedModules.xsl"/>
  <xsl:include href="rng2ditashellxsd.xsl"/>
  <xsl:include href="rng2ditaxsdmod.xsl"/>
  <xsl:include href="rng2xsdOasisOverrides.xsl"/>

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to DITA XSD Converter</xd:p>
      <xd:p><xd:b>Authors:</xd:b> ekimber</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
        shells and produces from them XSD-syntax vocabulary modules
        and shells that reflect the RNG definitions and conform to the DITA 1.3
        XSD coding requirements.
      </xd:p>
      <xd:p>The direct output is a conversion manifest, which simply
        lists the files generated. Each module and document type shell
        is generated separately using xsl:result-document.
      </xd:p>
    </xd:desc>
  </xd:doc>
  

 
  <!-- Output directory to put the generated XSD shell files in. 
      
       If not specified, output is relative to the input shell.
  -->
  <xsl:param name="outdir" as="xs:string" select="''"/>
  <!-- Output directory to put the generated DTD module files in.
       If not specified is the same as the output directory.
       This allows you to have shell DTDs go to one location and
       modules to another.
    -->
  <xsl:param name="moduleOutdir" as="xs:string" select="''"/>
  
  <!-- Set this parameter to "as-is" to output the comments exactly
       as they are within the RNG documentation and header comment
       elements.
    -->
  <xsl:param name="headerCommentStyle" select="'comment-per-line'" as="xs:string"/>
  <!-- Set this parameter to "comment-per-line" to get the OASIS module
       style of header comment.
    -->
  
  <xsl:param name="useURNsInShell" as="xs:string"
    select="'true'"
  >
    <!-- The XSDs can be generated to use either URNs or relative URLs
         in references to included XSD modules. The Technical Committee
         provides both forms of the XSDs.
      -->
  </xsl:param>
  
  <!-- Generate modules in addition shells. Default is to only generate
       shells.
       
    -->
  <xsl:param name="generateModules" as="xs:string" select="'false'"/>
  <xsl:variable name="doGenerateModules" as="xs:boolean"
    select="matches($generateModules, 'true|yes|1|on', 'i')"
  />
  
  <xsl:param name="generateStandardModules" as="xs:string" select="'false'"/>
  <xsl:variable name="doGenerateStandardModules" as="xs:boolean"
    select="matches($generateStandardModules, 'true|yes|1|on', 'i')"
  />

  <!-- The DITA version to generate the XSDs for. Values are 1.2 or 1.3.
       Default is 1.3.
    -->
  <xsl:param name="ditaVersion" as="xs:string"
    select="'1.3'"
  />

  <xsl:variable name="doUseURNsInShell" as="xs:boolean"
    select="matches($useURNsInShell, '(yes|true|1|no)', 'i')"
  />
  
  <!-- NOTE: The primary output of this transform is an XML 
       manifest file that lists all input files and their
       corresponding outputs.
    -->
  <xsl:output 
    method="xml"
    indent="yes"
  />

  <!-- Output method used to generate the XSD-syntax result files. -->
  <xsl:output name="xsd"
    method="xml"
    indent="yes"
    encoding="UTF-8"
  />

  <xsl:param name="rootDir" as="xs:string" required="no"/>
  
  <xsl:param name="debug" as="xs:string" select="'false'"/>
  
  <xsl:variable name="doDebug" as="xs:boolean" 
    select="matches($debug, '(true|yes|1|on)', 'i')" />

  <xsl:strip-space elements="*"/>
  
  <xsl:key name="definesByName" match="rng:define" use="@name" />
  <xsl:key name="elementsByName" match="rng:element" use="@name" />
  <xsl:key name="attlistIndex" match="rng:element" use="rng:ref[ends-with(@name, '.attlist')]/@name" />
  
  <xsl:template name="processDir">
    <!-- Template to process a directory tree. The "rootDir" parameter must
         be set, either the parent dir of the source document or explicitly
         specified as a runtime parameter.
      -->
    <!-- NOTE: This template is almost the same as the same template
         in the rng2ditadtd.xsl transform but I couldn't find a
         way to usefully factor out the common code because templates
         and functions can't return multiple values (or lists of lists)
         in XSLT 2.
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
    
    <xsl:variable name="shellDocs" as="document-node()*"
      select="for $doc in $rngDocs 
      return if (rngfunc:isShellGrammar($doc))
      then $doc
      else ()
      "
    />

    <xsl:variable name="referencedModules" as="document-node()*">
      <xsl:for-each select="$shellDocs">
        <xsl:apply-templates mode="getIncludedModules" select="./*">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Referenced modules:
<xsl:sequence select="for $doc in $referencedModules return concat(document-uri($doc), '&#x0a;')"/>      
      </xsl:message>
    </xsl:if>    
    
    <xsl:variable name="moduleDocs" as="document-node()*"
      select="(for $doc in $rngDocs 
                return if (matches(string(document-uri($doc)), '.+Mod.rng'))
                          then $doc
                          else ()), 
                $referencedModules except (rngDocs)
      "
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Shell documents to process:</xsl:message>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:for-each select="$shellDocs">
        <xsl:message> + [DEBUG]  <xsl:value-of 
          select="substring-after(string(document-uri(.)), concat($effectiveRootDir, '/'))"/></xsl:message>
      </xsl:for-each>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:message> + [DEBUG] Module documents to process:</xsl:message>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:for-each select="$moduleDocs">
        <xsl:message> + [DEBUG] - <xsl:value-of select="/*/ditaarch:moduleDesc/ditaarch:moduleTitle"/></xsl:message>
        <xsl:message> + [DEBUG]    <xsl:value-of 
          select="substring-after(string(document-uri(.)), concat($effectiveRootDir, '/'))"/></xsl:message>
      </xsl:for-each>
      <xsl:message> + [DEBUG]</xsl:message>
    </xsl:if>    
    
    <!-- Construct the set of all modules.
      -->
    <xsl:message> + [INFO] Getting list of unique modules...</xsl:message>
    <!-- Construct list of unique modules -->
    <xsl:variable name="modulesToProcess" as="document-node()*">
      <xsl:for-each-group select="$moduleDocs" group-by="string(document-uri(.))">
        <xsl:sequence select="."/><!-- Select first member of each group -->
      </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:if test="count($modulesToProcess) = 0">
      <xsl:message terminate="yes"> - [ERROR] construction of $modulesToProcess failed. Count is <xsl:value-of select="count($modulesToProcess)"/>, should be greater than zero</xsl:message>
    </xsl:if>
    
    <xsl:message> + [INFO] Removing div elements from modules...</xsl:message>
    
    <!-- Now preprocess the modules to remove rng:div elements: -->
    <xsl:variable name="modulesNoDivs" as="document-node()*">
      <xsl:for-each select="$modulesToProcess">
        <xsl:apply-templates mode="removeDivs" select=".">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:if test="count($modulesNoDivs) lt count($modulesToProcess)">
      <xsl:message terminate="yes"> - [ERROR] construction of $modulesNoDivs failed. Count is <xsl:value-of select="count($modulesNoDivs)"/>, should be <xsl:value-of select="count($modulesToProcess)"/></xsl:message>
    </xsl:if>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Got <xsl:value-of select="count($modulesNoDivs)"/> modulesNoDivs.</xsl:message>
    </xsl:if>
    
    <!-- NOTE: At this point, the modules have been preprocessed to remove
         <div> elements. This means that any module may be an intermediate
         document-node that has no associated document-uri() value. The @origURI
         attribute will have been added to the root element so we know where
         it came from.
      -->
    
    <xsl:variable name="schemaDirName" as="xs:string"
      select="if ($doUseURNsInShell) then 'schema' else 'schama-url'"
    />
    
    <xsl:variable name="schemaOutputDir" as="xs:string"
      select="if ($outdir = '') 
      then relpath:newFile($effectiveRootDir, $schemaDirName) 
      else relpath:toUrl(relpath:getAbsolutePath($outdir))"
    />
    
    <xsl:message> + [INFO] Generating XSD files...</xsl:message>
    
    <rng2ditaxsd:conversionManifest xmlns="http://dita.org/rng2ditadtd"
      timestamp="{current-dateTime()}"
      processor="{'rng2ditaxsd.xsl'}"
      ditaVersion="{$ditaVersion}"
      useURNsInShell="{$useURNsInShell}"      
      >
      <generatedShells>
        <xsl:message> + [INFO] Generating shell Schemas...</xsl:message>
        <xsl:apply-templates select="$shellDocs[($doGenerateStandardModules) or
                                   not(rngfunc:isStandardModule(.))]" mode="processShell">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
          <xsl:with-param name="schemaOutputDir" as="xs:string" tunnel="yes"
            select="$schemaOutputDir"
          />
          <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
            select="$modulesNoDivs"
          />
        </xsl:apply-templates>
      </generatedShells>
      <xsl:if test="$doGenerateModules">
        <xsl:message> + [INFO] =================================</xsl:message>
        <xsl:message> + [INFO] Generating Mod.xsd and Grp.xsd files...</xsl:message>
        <xsl:call-template name="ensureXmlXsd">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
          <xsl:with-param name="xsdOutputDir" as="xs:string" tunnel="yes"
            select="$schemaOutputDir"
          />
        </xsl:call-template>
        <xsl:call-template name="ensureDitaArchXsd">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
          <xsl:with-param name="xsdOutputDir" as="xs:string" tunnel="yes"
            select="$schemaOutputDir"
          />
        </xsl:call-template>
        <generatedModules>
          <xsl:apply-templates select="$modulesNoDivs[($doGenerateStandardModules) or
                                   not(rngfunc:isStandardModule(.))]" mode="processModules">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
            <xsl:with-param name="schemaOutputDir" as="xs:string" tunnel="yes"
              select="$schemaOutputDir"
            />
            <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
              select="$modulesNoDivs"
            />
          </xsl:apply-templates>
        </generatedModules>
      </xsl:if>
    </rng2ditaxsd:conversionManifest>
    <xsl:message> + [INFO] Done.</xsl:message>
  </xsl:template>
  
  <xsl:template match="/" mode="processModules">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:param 
      name="schemaOutputDir"
      tunnel="yes" 
      as="xs:string"
    />
    <xsl:variable name="rngModuleUrl" as="xs:string"
      select="if (*/@origURI) then */@origURI else base-uri(.)"
    />
    <xsl:message> + [INFO] processModules: Handling module <xsl:value-of select="$rngModuleUrl"/>...</xsl:message>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: rngModuleUrl="<xsl:sequence
        select="$rngModuleUrl"/>"</xsl:message>
      <xsl:message> + [DEBUG] generate-modules: schemaOutputDir="<xsl:sequence
        select="$schemaOutputDir"/>"</xsl:message>
    </xsl:if>
    <!-- Use the RNG module's grandparent directory name to construct output
         dir so the DTD module organization mirrors the RNG organization.
         This should always do the right thing for the OASIS-provided 
         modules.
         
         The general file organization pattern for OASIS-provided vocabulary files 
         is:
         
         doctypes/{packagename}/{typename}/{module file}
         
         e.g.:
         
         doctypes/base/rng/topicMod.rng
         doctypes/base/dtd/topic.mod
         
      -->
    <xsl:variable name="packageName" as="xs:string"
      select="relpath:getName(relpath:getParent(relpath:getParent($rngModuleUrl)))"
    />
    
    <!-- Put the Schema files in a directory named "schema/ or schema-url" -->
    
    <xsl:variable name="schemaDirName" as="xs:string"
      select="'xsd'"
    />
    
    <xsl:variable name="resultDir"
      select="relpath:newFile(relpath:newFile($schemaOutputDir, $packageName), $schemaDirName)"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: resultDir="<xsl:sequence select="$resultDir"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="rngModuleName" as="xs:string"
      select="relpath:getNamePart($rngModuleUrl)" />
    <!-- At this point we have the base name for the RNG module.
         Now we have to further modify it to reflect the orignal
         1.2 XSD module names, which don't all following the
         module naming conventions.
      -->
    <xsl:variable name="xsdModuleBaseName" as="xs:string"
      select="rngfunc:getXsdModuleBaseFilename($rngModuleName)"
    />
    <xsl:variable name="modFilename" as="xs:string"
      select="concat($xsdModuleBaseName, '.xsd')"
    />
    <xsl:variable name="grpFilename" as="xs:string"
      select="if (ends-with($xsdModuleBaseName, 'Mod'))
      then concat(substring-before($xsdModuleBaseName, 'Mod'), 'Grp.xsd')
      else concat($xsdModuleBaseName, 'Grp.xsd')"
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(./*)"
    />
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(./*)"
    />
    <xsl:variable name="modResultUrl"
      select="relpath:newFile($resultDir, $modFilename)" />
    <xsl:variable name="grpResultUrl"
      select="relpath:newFile($resultDir, $grpFilename)" />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processModules: / - Constructing normalized grammar...</xsl:message>
    </xsl:if>
    <xsl:variable name="normalizedGrammar" as="document-node()">
      <xsl:apply-templates select="." mode="normalize">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processModules: / - Normalized grammar constructed.</xsl:message>
    </xsl:if>
    
    
    <!-- Now generate the Mod and Grp files -->
    
    <moduleFiles xmlns="http://dita.org/rng2ditadtd">
      <inputFile><xsl:sequence select="$rngModuleUrl" /></inputFile>
      <modFile><xsl:sequence select="$modResultUrl" /></modFile>
      <!-- FIXME: Generate grp files when needed -->
    </moduleFiles>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processModules: Applying templates in mode generate-modules to generate "<xsl:value-of select="$modResultUrl"/>"</xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="generate-modules" select="."><!-- Root template for generate-modules matches on document, not rng:grammar -->
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>                 
      <xsl:with-param name="xsdOutputDir"
        select="$schemaOutputDir"
        tunnel="yes"
        as="xs:string"
      />
      <xsl:with-param name="normalizedGrammar" 
        as="document-node()" 
        tunnel="yes" 
        select="$normalizedGrammar"/>
    </xsl:apply-templates>        
   
  </xsl:template>
  
  

  <xsl:template match="/">

    <!-- The base directory under which all output will be generated. This
         implements the organization structure of the OASIS-provided modules,
         such that all generated files reflect the same relative locations
         as for the RNG modules.
      -->
    <!-- For OASIS modules, any shell will be in rng/{package}/rng
         The output needs to be in {schematype}/{package}/xsd
      -->
    <xsl:variable name="schemaOutputDir" as="xs:string"
      select="if ($outdir = '') 
                 then relpath:newFile(relpath:getParent(relpath:getParent(relpath:getParent(string(base-uri(.))))), 'xsd') 
                 else relpath:toUrl(relpath:getAbsolutePath($outdir))"
    />
    
    <xsl:message> + [INFO] Schema output directory is  "<xsl:sequence select="$schemaOutputDir"/>"</xsl:message>

    <!-- STEP 1: Figure out the RNG modules to be processed: -->
    <!-- Construct a sequence of all the input modules so we can
         then process them serially, rather than in tree order.
         We have to do this because in XSLT you can't start a new
         result document while you're in the process of creating
         another result document.
         
         WEK: I subsequently realized/was shown that you can simplify
         the process by holding each document in a variable while
         processing it and its descendants and then immediately output
         the variable to a document—no need to hold all the documents
         in memory and then put them out. However, not going to apply
         this new understanding to this process at this late date since
         this approach works and doesn't present any particular memory
         problems for the data sets that will be processed.
      -->
    <xsl:variable name="modulesToProcess" as="document-node()*">
      <xsl:apply-templates mode="gatherModules" >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="origModule" select="root(.)"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <!-- NOTE: At this point, the modules have been preprocessed to remove
         <div> elements. This means that any module may be an intermediate
         node that has no associated document-uri() value. The @origURI
         attribute will have been added to the root element so we know where
         it came from.
      -->
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Initial process: Found <xsl:sequence select="count($modulesToProcess)" /> modules.</xsl:message>
    </xsl:if>
    
    <!-- Step 1.5: Construct a version of the root grammar with all references
         and includes resolved.
      -->
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Constructing normalized grammar...</xsl:message>
    </xsl:if>
    <xsl:variable name="normalizedGrammar" as="document-node()">
      <xsl:apply-templates select="." mode="normalize">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="modulesToProcess" as="document-node()*" tunnel="yes" select="$modulesToProcess"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Normalized grammar constructed.</xsl:message>
    </xsl:if>

    <!-- STEP 2: Generate the manifest and process the modules: -->
    
    <xsl:variable name="rngShellUrl" as="xs:string"
      select="string(base-uri(root(.)))" />

    <rng2ditaxsd:conversionManifest xmlns="http://dita.org/rng2ditadtd">
      <inputDoc><xsl:value-of select="base-uri(root(.))"></xsl:value-of></inputDoc>
      <xsl:choose>
        <xsl:when test="count(rng:grammar/*)=1 and rng:grammar/rng:include">
          <!--  simple redirection, as in technicalContent/glossary.xsd -->
            <redirectedTo>
              <xsl:value-of select="concat(substring-before(rng:grammar/rng:include/@href,'.rng'),'.xsd')" />
            </redirectedTo>
        </xsl:when>
        <xsl:otherwise>
          <generatedModules>
            <xsl:apply-templates select="$modulesToProcess" mode="generate-modules">
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="xsdOutputDir"
                select="$schemaOutputDir"
                tunnel="yes"
                as="xs:string"
              />
              <xsl:with-param name="rngShellUrl" select="$rngShellUrl" tunnel="yes" as="xs:string"/>
              <xsl:with-param name="modulesToProcess" as="document-node()*"
                tunnel="yes"
                select="$modulesToProcess"
              />
              <xsl:with-param name="normalizedGrammar" as="document-node()" 
                select="$normalizedGrammar" 
                tunnel="yes"
              />
            </xsl:apply-templates>
          </generatedModules>
      </xsl:otherwise>
    </xsl:choose>

    <!-- Generate the .xsd file: -->
    <xsl:variable name="packageName" as="xs:string" 
      select="relpath:getName(relpath:getParent(relpath:getParent($rngShellUrl)))"
    />
    <xsl:variable name="xsdFilename" as="xs:string"
      select="concat(relpath:getNamePart($rngShellUrl), '.xsd')" />
    <xsl:variable name="xsdResultUrl"
      select="relpath:newFile(relpath:newFile(relpath:newFile($schemaOutputDir, $packageName), 'xsd'), $xsdFilename)" 
    />
      
    <xsdFile><xsl:sequence select="$xsdResultUrl" /></xsdFile>
    <xsl:result-document href="{$xsdResultUrl}" format="xsd">
      <xsl:apply-templates mode="xsdFile">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="xsdFilename" select="$xsdFilename" tunnel="yes" as="xs:string" />
        <xsl:with-param name="xsdDir" select="$schemaOutputDir" tunnel="yes" as="xs:string" />
        <xsl:with-param name="modulesToProcess"  select="$modulesToProcess" tunnel="yes" as="document-node()*" />
        <xsl:with-param name="rngShellUrl" select="$rngShellUrl" tunnel="yes" as="xs:string"/>
        <xsl:with-param name="normalizedGrammar" as="document-node()" 
          select="$normalizedGrammar" 
          tunnel="yes"
        />
      </xsl:apply-templates>
    </xsl:result-document>
    </rng2ditaxsd:conversionManifest>

  </xsl:template>
  

  <xsl:template match="/" mode="generate-modules">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param 
      name="xsdOutputDir"
      tunnel="yes" 
      as="xs:string"
    />
    
    <xsl:variable name="rngModuleUrl" as="xs:string"
      select="if (*/@origURI) then */@origURI else base-uri(.)"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: rngModuleUrl="<xsl:sequence
        select="$rngModuleUrl"/>"</xsl:message>
    </xsl:if>
    <!-- Use the RNG module's grandparent directory name to construct output
         dir so the XSD module organization mirrors the RNG organization.
         This should always do the right thing for the OASIS-provided 
         modules.
         
         The general file organization pattern for OASIS-provided vocabulary files 
         is:
         
         doctypes/{packagename}/{typename}/{module file}
         
         e.g.:
         
         doctypes/base/rng/topicMod.rng
         doctypes/base/xsd/topicMod.xsd
         
      -->
    <xsl:variable name="packageName" as="xs:string"
      select="relpath:getName(relpath:getParent(relpath:getParent($rngModuleUrl)))"
    />

    <!-- Put the XSD files in a directory named "xsd/" -->
    <xsl:variable name="resultDir"
      select="relpath:newFile(relpath:newFile($xsdOutputDir, $packageName), 'xsd')"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: resultDir="<xsl:sequence select="$resultDir"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="rngModuleName" as="xs:string"
      select="relpath:getNamePart($rngModuleUrl)" />
    
    <xsl:variable name="moduleBaseName" as="xs:string"
      select="rngfunc:getXsdModuleBaseFilename($rngModuleName)"
    />
    <xsl:variable name="xsdModuleBaseName" as="xs:string"
      select="rngfunc:getXsdModuleBaseFilename($moduleBaseName)"
    />
    <xsl:variable name="grpFilename" as="xs:string"
      select="if (ends-with($xsdModuleBaseName, 'Mod'))
      then concat(substring-before($xsdModuleBaseName, 'Mod'), 'Grp.xsd')
      else concat($xsdModuleBaseName, 'Grp.xsd')"
    />
    <xsl:variable name="modFilename" as="xs:string"
      select="concat($xsdModuleBaseName, '.xsd')"
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(./*)"
    />
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(./*)"
    />
    <xsl:variable name="grpResultUrl"
      select="relpath:newFile($resultDir, $grpFilename)" />
    <xsl:variable name="modResultUrl"
      select="relpath:newFile($resultDir, $modFilename)" />

    <!-- Now generate the Mod and Grp file  -->

    <moduleFiles xmlns="http://dita.org/rng2ditadtd">
      <inputFile><xsl:sequence select="$rngModuleUrl" /></inputFile>
      <grpFile><xsl:sequence select="$grpResultUrl" /></grpFile>
      <modFile><xsl:sequence select="$modResultUrl" /></modFile>
    </moduleFiles>
    <!-- Only structural modules and base modules have Grp files. -->
    <xsl:if test="$moduleType = ('topic', 'map', 'base')">
    <!-- Generate the Grp.xsd file: -->
      <xsl:result-document href="{$grpResultUrl}" format="xsd">
        <xsl:apply-templates mode="groupFile">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="thisFile" select="$grpResultUrl" tunnel="yes" as="xs:string" />
        </xsl:apply-templates>
      </xsl:result-document>
    </xsl:if>
    <!-- Generate the Mod.xsd file:  -->
    <xsl:result-document href="{$modResultUrl}" format="xsd">
      <xsl:apply-templates mode="moduleFile" >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="thisFile" select="$modResultUrl" tunnel="yes" as="xs:string" />
      </xsl:apply-templates>
    </xsl:result-document>
    
  </xsl:template>
  
  <xsl:template name="reportParameters">
    <xsl:message> + [INFO] Parameters:
      
      debug              ="<xsl:value-of select="$debug"/>"
      ditaVersion        ="<xsl:value-of select="$ditaVersion"/>"
      generateModules    ="<xsl:value-of select="concat($generateModules, ' (', $doGenerateModules, ')')"/>"
      headerCommentStyle ="<xsl:value-of select="$headerCommentStyle"/>"
      moduleOutdir       ="<xsl:value-of select="$moduleOutdir"/>"
      outdir             ="<xsl:value-of select="$outdir"/>"
      useURNsInShell     ="<xsl:value-of select="concat($useURNsInShell, ' (', $doUseURNsInShell, ')')"/>"
      
    </xsl:message>        
    
  </xsl:template>

  <xsl:template mode="#all" match="rng:define[@name = 'idElements']" priority="100">
    <!-- This pattern is only relevant to RNG and RNC grammars. Suppress it in the DTDs
      -->
  </xsl:template>

  <!-- ==============================
       Other modes and functions
       ============================== -->

  <xsl:template match="text()" mode="#all" priority="-1" >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>

  <xsl:template match="rng:div" mode="#all">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- RNG div elements are "transparent" and have no special meaning
         for XSD output (except possibly in a few special cases) 
         
         Note that this is really here for safety since we filter out
         all the divs before doing any output processing once we have
         gathered the modules to be processed.
      -->
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
</xsl:stylesheet>