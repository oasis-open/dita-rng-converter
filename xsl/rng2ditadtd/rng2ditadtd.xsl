<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:rnga="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:rng2ditadtd="http://dita.org/rng2ditadtd"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:str="http://local/stringfunctions"
  xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc local rng2ditadtd"
  expand-text="yes"
  version="3.0"
  >
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to DITA DTD Converter</xd:p>
      <xd:p><xd:b>Created on:</xd:b> Feb 16, 2013</xd:p>
      <xd:p><xd:b>Authors:</xd:b> ekimber, pleblanc</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
        shells and produces DTD-syntax vocabulary modules
        that reflect the RNG definitions and conform to the DITA 1.3+
        DTD coding requirements.
      </xd:p>
      <xd:p>The direct output is a conversion manifest, which simply
        lists the files generated. Each module and document type shell
        is generated separately using xsl:result-document.
      </xd:p>
      <xd:p>A note about generating text:</xd:p>
      <xd:p>In XSLT 2, xsl:value-of returns text nodes (in XSLT 1 it
      returned document nodes). In any context where strings would
      be concatenated, including for-each and for-each-group, if 
      you use xsl:sequence to return strings, the strings will be
      concatenated using the rules for string sequence concatenation,
      which means a blank will be inserted between each string. However,
      if you use xsl:value-of to return text nodes, there is no
      concatenation.</xd:p>
      <xd:p>This means that the code uses xsl:sequence *only* to return
      non-string, non-text nodes. Anywhere that the code generates
      literal strings it uses xsl:value-of.</xd:p>
      <xd:p>This transform can process either a single input RNG shell
        or an entire directory tree containing shells to process.</xd:p>
      <xd:p>To process a directory, omit the source document and 
      specify the initial template "processDir" and set the parameter
      rootDir to URI of the directory to process.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:include href="fallback.xsl"/>
  <xsl:include href="../lib/relpath_util.xsl" />
  <xsl:include href="../lib/rng2functions.xsl"/>
  <xsl:include href="../lib/rng2gatherModules.xsl"/>
  <xsl:include href="../lib/rng2removeDivs.xsl"/>
  <xsl:include href="../lib/rng2normalize.xsl"/>
  <xsl:include href="../lib/rng2getReferencedModules.xsl"/>
  <xsl:include href="rng2ditashelldtd.xsl"/>
  <xsl:include href="rng2ditaent.xsl" />
  <xsl:include href="rng2ditamod.xsl" />
  <xsl:include href="mode-filter-not-allowed-patterns.xsl" />
  <xsl:include href="rng2dtdOasisOverrides.xsl"/>  
  
  <!-- When true, turn on generation of modules, otherwise, only generate
       shells.
    -->
  <xsl:param name="generateModules" as="xs:string" select="'false'"/>
  <xsl:variable name="doGenerateModules" as="xs:boolean"
    select="matches($generateModules, 'true|yes|1|on', 'i')"
  />

  <!-- When true, allows generation of the standard modules, otherwise
       only generate non-standard modules.
    -->
  <xsl:param name="generateStandardModules" as="xs:string" select="'false'"/>
  <xsl:variable name="doGenerateStandardModules" as="xs:boolean"
    select="matches($generateStandardModules, 'true|yes|1|on', 'i')"
  />

  <!-- Output directory to put the generated DTD shell files in. 
      
       If not specified, output is relative to the input shell.
  -->
  <xsl:param name="outdir" as="xs:string" select="''"/>
  <!-- Output directory to put the generated DTD module files in.
       If not specified is the same as the output directory.
       This allows you to have shell DTDs go to one location and
       modules to another.
    -->
  <xsl:param name="moduleOutdir" as="xs:string" select="$outdir"/>
  
  <!-- Set this parameter to "as-is" to output the comments exactly
       as they are within the RNG documentation and header comment
       elements.
    -->
  <xsl:param name="headerCommentStyle" select="'comment-per-line'" as="xs:string"/>
  
  <!-- Controls whether or not DTDs and XSDs use public IDs or URNs
       to refer to included modules or use direct URLs.
    -->
  <xsl:param name="usePublicIDsInShell" as="xs:string"
    select="'true'"
  />

  <xsl:param name="ditaVersion" as="xs:string"
    select="'1.2'"
  />

  <xsl:param name="debug" as="xs:string" select="'false'"/>
  
  <xsl:param name="rootDir" as="xs:string" required="no"/>
      
  <xsl:variable name="doUsePublicIDsInShell" as="xs:boolean"
    select="matches($usePublicIDsInShell, 'yes|true|1|on', 'i')"
  />
  
  
  <!-- FIXME: This is used by the catalog utility to resolve URIs through a catalog.
              
              This needs to be replaced with a list of catalogs
              and then used to construct a global map representing
              the resolved catalogs to be used for URI lookup.
    -->  
  <xd:doc>      
    <xd:param>$catalogs: File URL of [DITA-OT]/catalog-dita.xml</xd:param>
  </xd:doc>
  <xsl:param name="catalogs" as="xs:string?" select="()"/>
  
  <!-- NOTE: The primary output of this transform is an XML 
       manifest file that lists all input files and their
       corresponding outputs.
    -->
  <xsl:output 
    method="xml"
    indent="yes"
  />

  <!-- Output method used to generate the DTD-syntax result files. -->
  <xsl:output name="dtd"
    method="text"
  />

  <xsl:variable name="doDebug" as="xs:boolean" 
    select="matches($debug, 'true|yes|on|1', 'i')" 
  />

  <xsl:strip-space elements="*"/>
  
  <xsl:key name="definesByName" match="rng:define" use="@name" />
  <xsl:key name="attlistIndex" match="rng:element" use="rng:ref[ends-with(@name, '.attlist')]/@name" />
  
  <xsl:template name="processDir">
    <!-- Template to process a directory tree. The "rootDir" parameter must
         be set, either the parent dir of the source document or explicitly
         specified as a runtime parameter.
      -->
     <xsl:call-template name="reportParameters"/>

    <xsl:message>+ [INFO] Preparing documents to process...</xsl:message>
    <xsl:variable name="effectiveRootDir" as="xs:string" 
      select="if ($rootDir != '')
        then $rootDir
        else relpath:getParent(string(base-uri(root(.))))
      "/>
    <xsl:message>+ [INFO] processDir: effectiveRootDir="{$effectiveRootDir}"</xsl:message>
    <xsl:variable name="collectionUri" 
      select="concat($effectiveRootDir, '?', 
          'recurse=yes;',
          'select=*.rng'
          )" 
      as="xs:string"/>
    <xsl:variable name="rngDocs" as="document-node()*"
      select="collection(iri-to-uri($collectionUri))"
    />

    <xsl:if test="$doDebug or true()">
      <xsl:message>+ [DEBUG] rngDocs:
 {
        $rngDocs ! (relpath:getName(string(base-uri(.))) ||
        ', moduleType: ' || rngfunc:getModuleType(./*) ||
        ', isShell: ' || rngfunc:isShellGrammar(.) ||
        ', isModuleDoc: ' || rngfunc:isModuleDoc(.) ||
        '&#x0a;')}        
      </xsl:message>
    </xsl:if>    
    <xsl:variable name="shellDocs" as="document-node()*"
      select="$rngDocs ! (if (rngfunc:isShellGrammar(.)) then . else ())
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
      <xsl:message>+ [DEBUG] Referenced modules:
        <xsl:sequence 
          select="$referencedModules ! string(base-uri(./*)) => string-join('&#x0a;')"
        />      
      </xsl:message>
      <xsl:message>+ [DEBUG] Referenced modules: document-uri() vs base-uri():
        <xsl:for-each select="$referencedModules">
          <xsl:message>+ [DEBUG] [{position()}] ------------</xsl:message>
          <xsl:message>+ [DEBUG] document-uri()="{document-uri(root(.))}"</xsl:message>
          <xsl:message>+ [DEBUG] base-uri()="{base-uri(root(.))}"</xsl:message>          
        </xsl:for-each>
        <xsl:message>+ [DEBUG] ------------</xsl:message>
      </xsl:message>
    </xsl:if>    
    
    <xsl:variable name="moduleDocs" as="document-node()*"
      select="
        (for $doc in $rngDocs 
         return 
           if (matches(string(base-uri($doc/*)), '.+Mod.rng'))
           then $doc
           else ()), 
         $referencedModules
      "
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] Have {count($shellDocs)} shell documents to process:</xsl:message>
        <xsl:message>+ [DEBUG]</xsl:message>
        <xsl:for-each select="$shellDocs">
          <xsl:message>+ [DEBUG] - {/*/ditaarch:moduleDesc/ditaarch:moduleTitle}: {string(base-uri(./*))}</xsl:message>
        </xsl:for-each>
        <xsl:message>+ [DEBUG]</xsl:message>
        <xsl:message>+ [DEBUG] Module documents to process:</xsl:message>
        <xsl:message>+ [DEBUG]</xsl:message>
        <xsl:for-each select="$moduleDocs">
          <xsl:message>+ [DEBUG] - {/*/ditaarch:moduleDesc/ditaarch:moduleTitle}</xsl:message>
          <xsl:message>+ [DEBUG]    {substring-after(string(base-uri(.)), concat($effectiveRootDir, '/'))}</xsl:message>
        </xsl:for-each>
        <xsl:message>+ [DEBUG]</xsl:message>
    </xsl:if>    
    
    <!-- Construct the set of all modules. This list may
         contain duplicates.
      -->

    <xsl:message>+ [INFO] Getting list of unique modules...</xsl:message>
    <!-- Construct list of unique modules -->
    <xsl:variable name="modulesToProcess" as="document-node()*">
      <xsl:for-each-group select="$moduleDocs" group-by="string(base-uri(./*))">
        <xsl:sequence select="."/><!-- Select first member of each group -->
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] getReferencedModules: $modulesToProcess="{for $mod in $modulesToProcess return rngfunc:getModuleShortName($mod/*)}"</xsl:message>      
    </xsl:if>
    
    <xsl:if test="count($modulesToProcess) = 0">
      <xsl:message terminate="yes"> - [ERROR] construction of modulesNoDivs failed. Count is {count($modulesToProcess)}, should be greater than zero</xsl:message>
    </xsl:if>
    
    <xsl:message>+ [INFO] Removing div elements from modules...</xsl:message>

    <!-- Now preprocess the modules to remove rng:div elements: -->
    <xsl:variable name="modulesNoDivs" as="document-node()*">
      <xsl:for-each select="$modulesToProcess">
         <xsl:apply-templates mode="removeDivs" select=".">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
         </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:if test="count($modulesNoDivs) lt count($modulesToProcess)">
      <xsl:message terminate="yes"> - [ERROR] construction of modulesNoDivs failed. Count is {count($modulesNoDivs)}, should be {count($modulesToProcess)}</xsl:message>
    </xsl:if>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] Got {count($modulesNoDivs)} modulesNoDivs.</xsl:message>
    </xsl:if>
    
    <!-- NOTE: At this point, the modules have been preprocessed to remove
         <div> elements.
      -->
    
    <xsl:variable name="dtdOutputDir" as="xs:string"
      select="if ($outdir = '') 
                 then relpath:newFile($effectiveRootDir, 'dtd') 
                 else relpath:getAbsolutePath($outdir)"
    />

    <xsl:message>+ [INFO] Generating DTD files in output directory "<xsl:sequence select="$dtdOutputDir"/>"...</xsl:message>
    
    <rng2ditadtd:conversionManifest xmlns="http://dita.org/rng2ditadtd"
      timestamp="{current-dateTime()}"
      processor="{'rng2ditadtd.xsl'}"
      >
      <xsl:message>+ [INFO] Generating shells...</xsl:message>
      <generatedShells>
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] applying templates to $shellDocs in mode processShell...</xsl:message>
        </xsl:if>
        <!-- FIXME: This predicate seems suspect. I think we want to generate shell docs in all cases
                    or we need a separate "generate shells" control.
          -->
        <xsl:apply-templates 
          select="
            $shellDocs[
              ($doGenerateStandardModules) or
              not(rngfunc:isStandardModule(.))
            ]" 
          mode="processShell">
          <xsl:with-param name="dtdOutputDir" as="xs:string" tunnel="yes"
            select="$dtdOutputDir"
          />
          <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
            select="$modulesNoDivs"
          />
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
        </xsl:apply-templates>
      </generatedShells>
      <xsl:message>+ [INFO] Shells generated</xsl:message>
      <xsl:if test="$doGenerateModules">
        <xsl:message>+ [INFO] =================================</xsl:message>
        <xsl:message>+ [INFO] Generating .mod and .ent files in directory "<xsl:sequence select="$dtdOutputDir"/>"...</xsl:message>
        
        <xsl:variable name="referencedModulesNoDivs" as="document-node()*"
          select="$modulesNoDivs[
                    ($doGenerateStandardModules) or
                    not(rngfunc:isStandardModule(.))
                  ]"
        />
        <xsl:variable name="notAllowedPatterns" as="element(rng:define)*"
            select="($shellDocs, $referencedModulesNoDivs/*)//rng:define[rng:notAllowed]"
        />        
        <xsl:variable name="notAllowedPatternNames" as="xs:string*"
          select="$notAllowedPatterns/@name ! string(.)"
        />
        
        <xsl:variable name="referencedModulesFiltered" as="document-node()*">
          <xsl:apply-templates select="$referencedModulesNoDivs" mode="filter-notallowed-patterns">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="notAllowedPatternNames" as="xs:string*" tunnel="yes" select="$notAllowedPatternNames"/>
          </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:if test="$doDebug or true()">
          <xsl:for-each select="$referencedModulesFiltered">
            <xsl:variable name="baseName" as="xs:string" select="relpath:getNamePart(base-uri(*[1]))"/>
            <xsl:variable name="resultUri" as="xs:string" select="relpath:newFile($outdir, 'temp/' || $baseName || '_filteredNotAllowed.rng')"/>
            <xsl:result-document href="{$resultUri}">
              <xsl:sequence select="."/>
            </xsl:result-document>
          </xsl:for-each>
        </xsl:if>
                
        <generatedModules>
          <xsl:apply-templates 
            select="$referencedModulesFiltered" 
            mode="processModules">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="dtdOutputDir" as="xs:string" tunnel="yes"
              select="$dtdOutputDir"
            />
            <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
              select="$modulesToProcess"
            />
            <xsl:with-param name="shellDocs" tunnel="yes" as="document-node()*"
              select="$shellDocs"
            />
            <xsl:with-param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*" select="$notAllowedPatterns"/>
            <xsl:with-param name="notAllowedPatternNames" tunnel="yes" as="xs:string*" select="$notAllowedPatternNames"/>            
          </xsl:apply-templates>
        </generatedModules>
      </xsl:if>
    </rng2ditadtd:conversionManifest>
    <xsl:message>+ [INFO] Done.</xsl:message>
  </xsl:template>

  <xsl:template match="/">
    <xsl:call-template name="reportParameters"/>    

    <xsl:variable name="dtdOutputDir" as="xs:string"
      select="if ($outdir = '') 
                 then relpath:newFile(relpath:getParent(relpath:getParent(relpath:getParent(string(base-uri(.))))), 'dtd') 
                 else relpath:getAbsolutePath($outdir)"
    />

    <xsl:variable name="modulesToProcess" as="document-node()*">
      <xsl:apply-templates mode="gatherModules" >
        <!-- FIXME: We won't need this once xml:base is in place for intermediate docs -->
        <xsl:with-param name="origModule" select="root(.)"/>
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:message>+ [INFO] Removing div elements from modules...</xsl:message>
    
    <!-- Now preprocess the modules to remove rng:div elements: -->
    <xsl:variable name="modulesNoDivs" as="document-node()*">
      <xsl:for-each select="$modulesToProcess">
        <xsl:apply-templates mode="removeDivs" select=".">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:variable>
    
    <rng2ditadtd:conversionManifest xmlns="http://dita.org/rng2ditadtd"
      timestamp="{current-dateTime()}"
      processor="{'rng2ditadtd.xsl'}"
      >
      <generatedShells>
        <xsl:apply-templates select="." mode="processShell">
          <xsl:with-param name="dtdOutputDir" as="xs:string" tunnel="yes"
            select="$dtdOutputDir"
          />
          <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
            select="$modulesNoDivs"
          />
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
        </xsl:apply-templates>
        
      </generatedShells>
      <xsl:if test="$doGenerateModules">
        <generatedModules>
          <xsl:apply-templates select="$modulesToProcess" mode="processModules">
            <xsl:with-param name="dtdOutputDir"
              select="$dtdOutputDir"
              tunnel="yes"
              as="xs:string"
            />
            <xsl:with-param name="modulesToProcess" as="document-node()*"
              tunnel="yes"
              select="$modulesToProcess"
            />          
          </xsl:apply-templates>
        </generatedModules>
      </xsl:if>  
    </rng2ditadtd:conversionManifest>
  </xsl:template>
  
  <!--
     Process a single RNG module document in order to generate the corresponding
     .ent and .mod files.
    -->
  <xsl:template match="/" mode="processModules">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param 
      name="dtdOutputDir"
      tunnel="yes" 
      as="xs:string"
    />
    
    <xsl:variable name="doDebug" as="xs:boolean" select="rngfunc:getModuleType(*) = ('contraint')"/>

    <xsl:variable name="rngModuleUrl" as="xs:string"
      select="string(base-uri(./*))"
    />
    <xsl:message>+ [INFO] processModules: Handling module {$rngModuleUrl}...</xsl:message>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-modules: rngModuleUrl="<xsl:sequence
        select="$rngModuleUrl"/>"</xsl:message>
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

    <!-- Put the DTD files in a directory named "dtd/" -->
    <xsl:variable name="resultDir"
      select="relpath:toUrl(relpath:newFile(relpath:newFile($dtdOutputDir, $packageName), 'dtd'))"
    />
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] generate-modules: resultDir="<xsl:sequence select="$resultDir"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="rngModuleName" as="xs:string"
      select="relpath:getNamePart($rngModuleUrl)" />
    <xsl:variable name="moduleBaseName" as="xs:string"
      select="if (ends-with($rngModuleName, 'Mod')) 
      then substring-before($rngModuleName, 'Mod') 
      else $rngModuleName"
    />
    <xsl:variable name="entFilename" as="xs:string"
      select="rngfunc:getEntityFilename(./*, 'ent')"
    />
    <xsl:variable name="modFilename" as="xs:string"
      select="rngfunc:getEntityFilename(./*, 'mod')"
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(./*)"
    />
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(./*)"
    />
    <xsl:variable name="entResultUrl"
      select="relpath:newFile($resultDir, $entFilename)" />
    <xsl:variable name="modResultUrl"
      select="relpath:newFile($resultDir, $modFilename)" />

    <!-- Now generate the .mod and .ent files: -->

    <moduleFiles xmlns="http://dita.org/rng2ditadtd">
      <inputFile><xsl:sequence select="$rngModuleUrl" /></inputFile>
      <entityFile><xsl:sequence select="$entResultUrl" /></entityFile>
      <modFile><xsl:sequence select="$modResultUrl" /></modFile>
    </moduleFiles>
    <!-- Generate the .ent file: -->
    <!-- NOTE: Not all base modules have .ent files -->
    <xsl:if test="
      not($moduleShortName = 
            ('tblDecl', 
             'metaDecl', 
             'map'))"
      >    
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] processModules: Applying templates in mode entityFile to generate "{$entResultUrl}"</xsl:message>
      </xsl:if>
      <!-- Constraint modules of all types do not have .ent files. Rather they declare all 
           required parameter entities in the main module.
        -->
      <xsl:if test="not($moduleType = ('constraint'))">
        <xsl:result-document href="{$entResultUrl}" format="dtd">
          <xsl:apply-templates mode="entityFile">
            <xsl:with-param name="dtdFilename" as="xs:string" tunnel="yes" select="$entFilename"/>
          </xsl:apply-templates>        
        </xsl:result-document>
      </xsl:if>
    </xsl:if>
    
    <!-- Generate the .mod file: NOTE: Attribute modules only have .ent files -->
    <xsl:if test="not($moduleType = ('attributedomain'))">
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] processModules: Applying templates in mode moduleFile to generate "{$modResultUrl}"</xsl:message>
      </xsl:if>
      <xsl:result-document href="{$modResultUrl}" format="dtd">
        <xsl:apply-templates mode="moduleFile" >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="dtdFilename" as="xs:string" tunnel="yes" select="$modFilename"/>
        </xsl:apply-templates>
      </xsl:result-document>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template mode="#all" match="rng:define[@name = 'idElements']" priority="100">
    <!-- This pattern is only relevant to RNG and RNC grammars. Suppress it in the DTDs
      -->
  </xsl:template>

  <!-- ==============================
       Other modes and functions
       ============================== -->
  
  <xsl:template name="reportParameters">
<xsl:message>+ [INFO] Parameters:
  
  debug              ="{$debug}"
  ditaVersion        ="{$ditaVersion}"
  generateModules    ="{$generateModules || ' (' || $doGenerateModules || ')'}"
  headerCommentStyle ="{$headerCommentStyle}"
  moduleOutdir       ="{$moduleOutdir}"
  outdir             ="{$outdir}"
  usePublicIDsInShell="{$usePublicIDsInShell || ' (' || $doUsePublicIDsInShell || ')'}"

</xsl:message>    
    
    
  </xsl:template>

</xsl:stylesheet>