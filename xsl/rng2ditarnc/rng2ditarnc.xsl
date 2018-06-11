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
  xmlns:dita="http://dita.oasis-open.org/architecture/2005/"
  xmlns:rngfunc="http://dita.oasis-open.org/dita/rngfunctions"
  xmlns:local="http://local-functions"
  exclude-result-prefixes="xs xd rng rnga relpath str rngfunc local rng2ditadtd"
  version="3.0">

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to DITA RNC Converter</xd:p>
      <xd:p><xd:b>Authors:</xd:b> ekimber</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
        shells and produces from them RNC-syntax vocabulary modules
        and shells that reflect the RNG definitions and conform to the DITA 1.3
        RNC coding requirements.
      </xd:p>
      <xd:p>The direct output is a conversion manifest, which simply
        lists the files generated. Each module and document type shell
        is generated separately using xsl:result-document.
      </xd:p>
    </xd:desc>
  </xd:doc>

  <xsl:include href="../lib/relpath_util.xsl" />
  <xsl:include href="../lib/rng2functions.xsl"/>
  <xsl:include href="../lib/rng2gatherModules.xsl"/>
  <xsl:include href="../lib/rng2generateCatalogs.xsl"/>
  <xsl:include href="../lib/rng2removeDivs.xsl"/>
  <xsl:include href="../lib/rng2normalize.xsl"/>
 
  <!-- Output directory to put the generated RNC shell files in. 
      
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
  
  <xsl:param name="generateModules" as="xs:string" select="'false'"/>
  <xsl:variable name="doGenerateModules" as="xs:boolean"
    select="matches($generateModules, 'true|yes|1|on', 'i')"
  />

  <xsl:param name="ditaVersion" as="xs:string"
    select="'1.3'"
  />

  <xsl:variable name="doUseURNsInShell" as="xs:boolean"
    select="matches($useURNsInShell, '(yes|true|1|no)', 'i')"
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
  <xsl:output name="rnc"
    method="text"
    encoding="UTF-8"
  />

  <xsl:param name="rootDir" as="xs:string" required="no"/>
  
  <xsl:param name="debug" as="xs:string" select="'false'"/>
  
  <xsl:variable name="doDebug" as="xs:boolean" select="$debug = 'true'" />
  
  <xsl:key name="definesByName" match="rng:define" use="@name" />
  
  <xsl:strip-space elements="*"/>
  
  
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
    
    <xsl:variable name="doDebug" as="xs:boolean" select="false()"/>
    
    <xsl:message> + [INFO] Preparing documents to process...</xsl:message>
    <xsl:variable name="effectiveRootDir" as="xs:string" 
      select="if ($rootDir != '')
      then $rootDir
      else relpath:getParent(base-uri(root(.)/*))
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
    <!-- FIXME: Need to use module metadata, not filenames -->
    <xsl:variable name="moduleDocs" as="document-node()*"
      select="for $doc in $rngDocs 
      return if (matches(string(base-uri($doc/*)), '.+Mod.rng'))
      then $doc
      else ()
      "
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Shell documents to process:</xsl:message>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:for-each select="$shellDocs">
        <xsl:message> + [DEBUG]  <xsl:value-of 
          select="substring-after(string(base-uri(./*)), concat($effectiveRootDir, '/'))"/></xsl:message>
      </xsl:for-each>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:message> + [DEBUG] Module documents to process:</xsl:message>
      <xsl:message> + [DEBUG]</xsl:message>
      <xsl:for-each select="$moduleDocs">
        <xsl:message> + [DEBUG] - <xsl:value-of select="/*/ditaarch:moduleDesc/ditaarch:moduleTitle"/></xsl:message>
        <xsl:message> + [DEBUG]    <xsl:value-of 
          select="substring-after(string(base-uri(./*)), concat($effectiveRootDir, '/'))"/></xsl:message>
      </xsl:for-each>
      <xsl:message> + [DEBUG]</xsl:message>
    </xsl:if>    
    
    <!-- Construct the set of all modules. This list may
         contain duplicates.
      -->
    <xsl:message> + [INFO] Getting list of unique modules...</xsl:message>
    <!-- Construct list of unique modules -->
    <xsl:variable name="modulesToProcess" as="document-node()*">
      <xsl:for-each-group select="$moduleDocs" group-by="string(base-uri(./*))">
        <xsl:sequence select="."/><!-- Select first member of each group -->
      </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:if test="count($modulesToProcess) = 0">
      <xsl:message terminate="yes"> - [ERROR] construction of modulesNoDivs failed. Count is <xsl:value-of select="count($modulesToProcess)"/>, should be greater than zero</xsl:message>
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
      <xsl:message terminate="yes"> - [ERROR] constructionof modulesNoDivs failed. Count is <xsl:value-of select="count($modulesNoDivs)"/>, should be <xsl:value-of select="count($modulesToProcess)"/></xsl:message>
    </xsl:if>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] Got <xsl:value-of select="count($modulesNoDivs)"/> modulesNoDivs.</xsl:message>
    </xsl:if>
    
    <!-- FIXME: All modules should have xml:base on the root element so there is always a good base URI value. -->
    <!-- NOTE: At this point, the modules have been preprocessed to remove
         <div> elements. This means that any module may be an intermediate
         document-node that has no associated document-uri() value. The @origURI
         attribute will have been added to the root element so we know where
         it came from.
      -->
    
    <xsl:variable name="rncOutputDir" as="xs:string"
      select="if ($outdir = '') 
      then relpath:newFile($effectiveRootDir, 'rnc') 
      else relpath:toUrl(relpath:getAbsolutePath($outdir))"
    />
    
    <xsl:message> + [INFO] Generating RNC files...</xsl:message>
    
    <rng2ditadtd:conversionManifest xmlns="http://dita.org/rng2ditadtd"
      timestamp="{current-dateTime()}"
      processor="{'rng2ditarnc.xsl'}"
      >
      <generatedShells>
        <xsl:message> + [INFO] Generating shell RNCs...</xsl:message>
        <xsl:apply-templates select="$shellDocs" mode="processGrammar">
          <xsl:with-param name="rncOutputDir" as="xs:string" tunnel="yes"
            select="$rncOutputDir"
          />
          <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
            select="$modulesNoDivs"
          />
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
        </xsl:apply-templates>
      </generatedShells>
      <xsl:if test="$doGenerateModules">
        <xsl:message> + [INFO] =================================</xsl:message>
        <xsl:message> + [INFO] Generating module RNC files...</xsl:message>
        <generatedModules>
          <xsl:apply-templates select="$modulesNoDivs" mode="processGrammar">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>         
            <xsl:with-param name="rncOutputDir" as="xs:string" tunnel="yes"
              select="$rncOutputDir"
            />
            <xsl:with-param name="modulesToProcess" tunnel="yes" as="document-node()*"
              select="$modulesToProcess"
            />
          </xsl:apply-templates>
        </generatedModules>
      </xsl:if>
    </rng2ditadtd:conversionManifest>
    <xsl:message> + [INFO] Done.</xsl:message>
  </xsl:template>
  
  <xsl:template match="/" mode="processGrammar">    
    <!-- Generates an RNC file from an RNG file -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:param 
      name="rncOutputDir"
      tunnel="yes" 
      as="xs:string"
    />
    <xsl:variable name="rngModuleUrl" as="xs:string"
      select="if (*/@origURI) then */@origURI else base-uri(.)"
    />
    
<!--    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
    
    <xsl:message> + [INFO] processModules: Handling module <xsl:value-of select="$rngModuleUrl"/>...</xsl:message>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: rngModuleUrl="<xsl:sequence
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
    
    <xsl:variable name="rncDirName" as="xs:string"
      select="'rnc'"
    />
    
    <xsl:variable name="resultDir"
      select="relpath:newFile(relpath:newFile($rncOutputDir, $packageName), $rncDirName)"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: resultDir="<xsl:sequence select="$resultDir"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="rngModuleName" as="xs:string"
      select="relpath:getNamePart($rngModuleUrl)" />
    <xsl:variable name="moduleBaseName" as="xs:string"
      select="if (ends-with($rngModuleName, 'Mod')) 
      then substring-before($rngModuleName, 'Mod') 
      else $rngModuleName"
    />
    <xsl:variable name="rncFilename" as="xs:string"
      select="concat($rngModuleName, '.rnc')"
    />
    <xsl:variable name="moduleType" as="xs:string"
      select="rngfunc:getModuleType(./*)"
    />
    <xsl:variable name="moduleShortName" as="xs:string"
      select="rngfunc:getModuleShortName(./*)"
    />
    <xsl:variable name="rncResultUrl"
      select="relpath:newFile($resultDir, $rncFilename)" />
    
    <!-- Now generate the RNC files -->
    
    <moduleFiles xmlns="http://dita.org/rng2ditadtd">
      <inputFile><xsl:sequence select="$rngModuleUrl" /></inputFile>
      <modFile><xsl:sequence select="$rncResultUrl" /></modFile>
    </moduleFiles>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processModules: Applying templates in mode generate-modules to generate "<xsl:value-of select="$rncResultUrl"/>"</xsl:message>
    </xsl:if>
    <xsl:result-document href="{$rncResultUrl}" format="rnc">
      <xsl:apply-templates mode="generate-modules">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      </xsl:apply-templates>        
    </xsl:result-document>
    
  </xsl:template>
  
  <xsl:template mode="generate-modules" match="/ | rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-modules: Document root </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="dita:moduleDesc">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;namespace a = "http://relaxng.org/ns/compatibility/annotations/1.0"</xsl:text>
    <xsl:text>&#x0a;namespace dita = "http://dita.oasis-open.org/architecture/2005/"</xsl:text>
    <xsl:text>&#x0a;</xsl:text>
    <xsl:apply-templates select="* except (dita:moduleDesc)">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] #default: rng:grammar </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="dita:moduleDesc">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;namespace a = "http://relaxng.org/ns/compatibility/annotations/1.0"&#x0a;</xsl:text>
    <xsl:apply-templates select="* except (dita:moduleDesc)">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="dita:moduleDesc">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] #default: dita:moduleDesc </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="(dita:headerComment[starts-with(@fileType, 'rnc')], dita:headerComment[1])[1]">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="dita:headerComment">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] #default: dita:headerComment </xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="comment">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="comment" match="text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] comment: text(): "<xsl:sequence select="if (string-length(.) > 40) then concat(substring(., 1, 40), '...') else ."/> </xsl:message>
    </xsl:if>
    <xsl:text># </xsl:text>
    <xsl:analyze-string select="." regex="\n" flags="s">
      <xsl:matching-substring>
        <xsl:text>&#x0a;# </xsl:text>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  
  <xsl:template match="rng:start">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:div</xsl:message>
    </xsl:if>
    <text>&#x0a;start = </text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:ref, name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:variable name="targetName" select="local:escapeName(@name)" as="xs:string"/>
    <xsl:value-of select="$targetName"/>
  </xsl:template>

  <xsl:template match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:include</xsl:message>
    </xsl:if>
    <xsl:variable name="origHref" select="@href" as="xs:string"/>
    <!-- NOTE: This code exists because we need to generate RNC files in the same
               relative structure as the RNGs.
      -->
    <xsl:variable name="newHref" select="replace(replace($origHref, 'rng$', 'rnc'), '/rng/', '/rnc/')"/>
    <xsl:text>&#x0a;include </xsl:text>
    <xsl:text>"</xsl:text><xsl:value-of select="$newHref"/><xsl:text>"</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:externalRef">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:extenralRef</xsl:message>
    </xsl:if>
    <xsl:variable name="origHref" select="@href" as="xs:string"/>
    <xsl:variable name="newHref" select="replace(replace($origHref, 'rng$', 'rnc'), '/rng/', '/rnc/')"/>
    <xsl:text>&#x0a;external </xsl:text>    
    <xsl:text>"</xsl:text><xsl:value-of select="$newHref"/><xsl:text>"</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:div">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:div</xsl:message>
    </xsl:if>
    <text>&#x0a;div {</text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;}</xsl:text>
  </xsl:template>
 
  <xsl:template match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
<!--    <xsl:variable name="doDebug" select="string(@name) = 'any'" as="xs:boolean"/>-->
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:define, name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="assignMethod" as="xs:string"
      select="if (@combine = 'choice') then '|=' else if (@combine = 'interleave') then '&amp;=' else '='"
    />
    <xsl:text>&#x0a;</xsl:text>
    <xsl:value-of select="local:escapeName(@name)"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="$assignMethod"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" 
        select="$doDebug"/>
      <xsl:with-param name="sep" tunnel="yes" select="', '"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="rng:element">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:element</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>&#x0a;element </xsl:text>
    <xsl:apply-templates select="@name, (rng:name|rng:anyName|rng:nsName|
      rng:choice[rng:name|rng:anyName|rng:nsName])" mode="nameClass">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    </xsl:apply-templates>
    <xsl:text> {</xsl:text>
    <xsl:apply-templates select="* except (rng:name|rng:anyName|rng:nsName|
      rng:choice[rng:name|rng:anyName|rng:nsName])">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" tunnel="yes" select="', '"/>
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>    
  </xsl:template>

  <xsl:template match="rng:attribute">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:attribute, sep="<xsl:value-of select="$sep"/>", preceding-sibling::rng:*=<xsl:value-of select="boolean(preceding-sibling::rng:*)"/></xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:if test="$doDebug">      
        <xsl:message> + [DEBUG] default: rng:ref = putting out separator "<xsl:value-of select="$sep"/>"</xsl:message>
      </xsl:if>
      <xsl:value-of select="$sep"/>
    </xsl:if>
    
    <xsl:text>&#x0a;attribute </xsl:text>
    <xsl:apply-templates select="@name, (rng:name|rng:anyName|rng:nsName|rng:choice[rng:name|rng:anyName|rng:nsName])" mode="nameClass">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text> {</xsl:text>
    <xsl:if test="not(rng:value | rng:data | rng:choice | rng:ref) ">
      <xsl:text> text</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="* except  (rng:name|rng:anyName|rng:nsName|rng:choice[rng:name|rng:anyName|rng:nsName])">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>     
    </xsl:apply-templates>        
    <xsl:text>}</xsl:text>    
  </xsl:template>
  
  <xsl:template match="rng:data">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:data</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text> </xsl:text>
    <!-- FIXME: This assumes that all datatypes from the XSD type library -->
    <xsl:value-of select="concat('xsd:', @type)"/>
  </xsl:template>

  <xsl:template match="rng:value">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:value</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:text">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:text</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text> text </xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:name">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:name</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <!-- FIXME: Need to handle ns value -->
    <xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:template match="rng:empty">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:empty</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text> empty </xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:notAllowed">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:notAllowed</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text> notAllowed </xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:optional">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:optional</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>?</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:zeroOrMore">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:zeroOrMore</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and (preceding-sibling::rng:* and not(preceding-sibling::rng:name | preceding-sibling::rng:anyName))">
      <xsl:if test="$doDebug">      
        <xsl:message> + [DEBUG] default: rng:zeroOrMore = putting out separator "<xsl:value-of select="$sep"/>"</xsl:message>
      </xsl:if>
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>*</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:oneOrMore">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:optional</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xsl:text>+</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:choice">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:choice</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" select="' | '" tunnel="yes"/>
    </xsl:apply-templates>    
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:group">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:group</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" select="', '" tunnel="yes"/>
    </xsl:apply-templates>    
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:interleave">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:interleave</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" select="' &amp; '" tunnel="yes"/>
    </xsl:apply-templates>    
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:list">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="sep" select="''" tunnel="yes"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:list</xsl:message>
    </xsl:if>
    <xsl:if test="$sep != '' and preceding-sibling::rng:*">
      <xsl:value-of select="$sep"/>
    </xsl:if>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" select="', '" tunnel="yes"/>
    </xsl:apply-templates>    
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="rng:except">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:list</xsl:message>
    </xsl:if>
    <xsl:text> - </xsl:text>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      <xsl:with-param name="sep" select="' | '" tunnel="yes"/>
    </xsl:apply-templates>    
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  
  <!-- ==============================
       Mode: Annotations
       ============================== -->
  
  
  <xsl:template mode="annotations" match="*">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name(.)"/>
    <xsl:text> [</xsl:text>
    <xsl:apply-templates mode="#current" select="@*,node()"/>
    <xsl:text>]</xsl:text>
    
  </xsl:template>
  
  <xsl:template mode="annotations" match="text()">
    <!-- FIXME: This needs to handle quote escaping -->
    <xsl:text>"</xsl:text><xsl:value-of select="."/><xsl:text>" </xsl:text>
  </xsl:template>
  
  <xsl:template mode="annotations" match="@*">
    <!-- FIXME: This needs to handle tagnames that are the same as RNC keywords (e.g., "text"). -->
    <xsl:value-of select="name(.)"/>
    <xsl:text>=</xsl:text>
    <!-- FIXME: This needs to handle quote escaping -->
    <xsl:text>"</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>" </xsl:text>
  </xsl:template> 
  
  
  <!-- ==============================
       Mode: Nameclass
       ============================== -->
  
  <xsl:template mode="nameClass" match="@name">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] default: rng:@name</xsl:message>
    </xsl:if>
    <xsl:sequence select="local:escapeName(.)"/>
  </xsl:template>
  
  <xsl:template mode="nameClass" match="rng:choice | rng:ref">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template mode="nameClass #default" match="rng:anyName">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> + [DEBUG] nameClass or #default: rng:anyName</xsl:message>
    </xsl:if>
    <xsl:text> *</xsl:text>
    <xsl:apply-templates>
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- ==============================
       Catch-all templates
       ============================== -->
  
  <xsl:template match="rng:*" priority="-0.5">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> - [WARN] Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>
    
  </xsl:template>

  <xsl:template match="rng:*" priority="-0.5" mode="nameClass">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">      
      <xsl:message> - [WARN] nameClass: Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="*" priority="-1" mode="#all">
    <!-- Any non-rng namespace element is by definition an annotation -->
<!--    <xsl:text>&#x0a;[</xsl:text>-->
<!--    <xsl:apply-templates mode="annotations" select="."/>-->
<!--    <xsl:text>&#x0a;]</xsl:text>-->
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
  
  <xsl:function name="local:getModuleBaseFilename" as="xs:string">
    <xsl:param name="rngModuleName" as="xs:string"/>
    <xsl:variable name="moduleBaseName" as="xs:string"
      select="if (ends-with($rngModuleName, 'Mod')) 
      then substring-before($rngModuleName, 'Mod') 
      else $rngModuleName"
    />
    <xsl:sequence select="$moduleBaseName"/>

  </xsl:function>

  <xsl:function name="local:escapeName" as="xs:string">
    <xsl:param name="name" as="attribute()"/>
    <xsl:variable name="keywords" as="xs:string*"
      select="  
'attribute'
, 'default'
, 'datatypes'
, 'div'
, 'element'
, 'empty'
, 'external'
, 'grammar'
, 'include'
, 'inherit'
, 'list'
, 'mixed'
, 'namespace'
, 'notAllowed'
, 'parent'
, 'start'
, 'string'
, 'text'
, 'token'
"/>
    <xsl:variable name="result" as="xs:string"
      select="if (string($name) = $keywords) then concat('\', $name) else $name"
    />   
    <xsl:sequence select="$result"/>
  </xsl:function>
</xsl:stylesheet>