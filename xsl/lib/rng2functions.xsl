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
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Sep 21, 2013</xd:p>
      <xd:p><xd:b>Author:</xd:b> ekimber</xd:p>
      <xd:p>Defines utility functions for working with RNG-syntax DITA shells and modules.</xd:p>
    </xd:desc>
  </xd:doc>

  <xsl:function name="rngfunc:getModuleType" as="xs:string">
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:sequence select="rngfunc:getModuleType($rngGrammar, true())"/>
  </xsl:function>  
  
  <xsl:function name="rngfunc:getModuleType" as="xs:string">
    <!-- Returns the declared module type of the module -->
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:param name="reportNoModuleDesc" as="xs:boolean"/>
    <xsl:variable name="type" as="xs:string?"
      select="$rngGrammar/dita:moduleDesc/dita:moduleMetadata/dita:moduleType"
    />
    <xsl:choose>
      <xsl:when test="$type">
        <xsl:sequence select="$type"/>
      </xsl:when>
      <xsl:when test="not($reportNoModuleDesc)">
        <xsl:sequence select="'non-dita module'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> + [ERROR] No moduleType element in module description for module "<xsl:sequence select="rngfunc:getModuleTitle($rngGrammar)"/>"</xsl:message>
        <xsl:sequence select="'no module type'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="rngfunc:getXsdModuleBaseFilename" as="xs:string">
    <xsl:param name="rngModuleBaseName" as="xs:string"/>

    <!-- Names that do not end in "Mod" for the XSD: -->
    <xsl:variable name="removeModNames" as="xs:string*"
      select="('delayResolutionDomainMod', 
      'hazardstatementDomainMod',
      'highlightDomainMod',
      'indexingDomainMod',
      'utilitiesDomainMod',
      'learningDomainMod',
      'learningInteractionBaseDomainMod',
      'learningMapDomainMod',
      'learningMetadataDomainMod',
      'classifyDomainMod',
      'abbreviateDomainMod',
      'glossrefDomainMod',
      'programmingDomainMod',
      'softwareDomainMod',
      'taskreqDomainMod',
      'uiDomainMod',
      'xnalDomainMod'
      )"
    />
    <!-- Names that do not include Domain in the XSD: -->
    <xsl:variable name="removeDomainNames" as="xs:string*"
      select="('mapGroupDomainMod'
      )"
    />
    <!-- It appears that the XSD domain modules 
         consistently omit the "Mod" ending, while
         only mapGroupDomain does not include the "Domain"
         ending.
      -->
    <!-- The 1.2 XSDs use the name "commonElementMod", not "commonElementsMod" as they should.
         Can't change the filename in the 1.x release, so have to handle the special case.
      -->
    <xsl:variable name="result" as="xs:string"
      select="if ($rngModuleBaseName = $removeModNames)
      then substring-before($rngModuleBaseName, 'Mod') 
      else if ($rngModuleBaseName = $removeDomainNames)
      then concat(substring-before($rngModuleBaseName, 'Domain'), 'Mod')
      else if ($rngModuleBaseName = 'commonElementsMod') 
              then 'commonElementMod' 
              else $rngModuleBaseName"
    />
    
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <xsl:function name="rngfunc:getPublicId" as="xs:string">
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:param name="idType" as="xs:string"/>
    <xsl:sequence select="rngfunc:getPublicId($rngGrammar, $idType, false())"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getPublicId" as="xs:string">
    <!-- Returns the public ID of the specified type -->
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:param name="idType" as="xs:string"/>
    <xsl:param name="isVersionSpecific" as="xs:boolean"/>
    
    <xsl:variable name="pubId" as="xs:string?">
      <xsl:choose>
        <xsl:when test="$isVersionSpecific">
          <xsl:apply-templates mode="rngfunc:constructPublicId"
            select="$rngGrammar/dita:moduleDesc/dita:moduleMetadata/*/*[local-name(.) = $idType]"
            >
            <xsl:with-param name="isVersionSpecific" as="xs:boolean" tunnel="yes" select="$isVersionSpecific"/>
          </xsl:apply-templates>          
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$rngGrammar/dita:moduleDesc/dita:moduleMetadata/*/*[local-name(.) = $idType]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$pubId">
        <xsl:sequence select="$pubId"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> + [ERROR] No public ID element "<xsl:sequence select="$idType"/>" in module description for module "<xsl:sequence select="rngfunc:getModuleTitle($rngGrammar)"/>"</xsl:message>
        <xsl:sequence select="concat('noPublicId type ', $idType)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template mode="rngfunc:constructPublicId" match="*">
    <xsl:variable name="rawValue">
      <xsl:value-of>
        <xsl:apply-templates mode="#current"/>
      </xsl:value-of>
    </xsl:variable>
    <xsl:sequence select="normalize-space($rawValue)"/>
  </xsl:template>
  
  <xsl:template mode="rngfunc:constructPublicId" match="text()">
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template mode="rngfunc:constructPublicId" match="dita:var[@name='ditaver']" priority="10">
    <xsl:variable name="presep" select="@presep" as="xs:string?"/>
    <xsl:variable name="postsep" select="@postsep" as="xs:string?"/>
    <xsl:value-of select="concat($presep, $ditaVersion, $postsep)"/>
  </xsl:template>
  
  <xsl:function name="rngfunc:getModuleShortName" as="xs:string">
    <!-- Returns the short name of the specified type -->
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:variable name="shortName" as="xs:string?"
      select="$rngGrammar/dita:moduleDesc/dita:moduleMetadata/dita:moduleShortName"
    />
    <xsl:choose>
      <xsl:when test="$shortName">
        <xsl:sequence select="$shortName"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message> + [ERROR] No moduleShortName element in module description for module "<xsl:sequence select="rngfunc:getModuleTitle($rngGrammar)"/>"</xsl:message>
        <xsl:sequence select="'noShortName'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="rngfunc:getModuleTitle" as="xs:string">
    <!-- Returns the title of the module -->
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:variable name="title" as="xs:string"
      select="if ($rngGrammar/dita:moduleDesc/dita:moduleTitle) 
      then $rngGrammar/dita:moduleDesc/dita:moduleTitle 
      else rngfunc:getGrammarUri($rngGrammar)"
    />
    <xsl:sequence select="$title"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isElementDomain" as="xs:boolean">
    <xsl:param name="grammarDoc" as="document-node()"/>
    <xsl:variable name="moduleType" as="xs:string" 
      select="rngfunc:getModuleType($grammarDoc/*)"/>
    <xsl:variable name="result" 
      as="xs:boolean"
      select="$moduleType = 'elementdomain'" 
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isAttributeDomain" as="xs:boolean">
    <xsl:param name="grammarDoc" as="document-node()"/>
    <xsl:variable name="moduleType" as="xs:string" 
      select="rngfunc:getModuleType($grammarDoc/*)"/>
    <xsl:variable name="result" 
      as="xs:boolean"
      select="$moduleType = 'attributedomain'" 
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <!-- Return true if the module is a map or topic structural type module. -->
  <xsl:function name="rngfunc:isTypeModule" as="xs:boolean">
    <xsl:param name="grammarDoc" as="document-node()"/>
    <xsl:variable name="moduleType" as="xs:string" 
      select="rngfunc:getModuleType($grammarDoc/*)"/>
    <xsl:variable name="result" 
      as="xs:boolean"
      select="$moduleType = ('topic', 'map')" 
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <!-- Return true if the module document is a constraint module. -->
  <xsl:function name="rngfunc:isConstraintModule" as="xs:boolean">
    <xsl:param name="moduleDoc" as="document-node()"/>
    <xsl:variable name="result" as="xs:boolean"
      select="rngfunc:getModuleType($moduleDoc/*) = 'constraint'"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  
  <xsl:function name="rngfunc:getEntityFilename" as="xs:string">
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:param name="entityType" as="xs:string"/><!-- 'ent' or 'mod' -->
    
    <xsl:variable name="baseRngName" as="xs:string"
      select="if ($entityType = 'ent' and 
                 (rngfunc:getModuleType($rngGrammar) = 'topic' and rngfunc:getModuleShortName($rngGrammar) = 'topic'))
      then 'topicDefn'
      else relpath:getNamePart(rngfunc:getGrammarUri($rngGrammar))"
    />
    <xsl:variable name="baseEntityNamePart" as="xs:string"
         select="
         if (ends-with($baseRngName, 'Mod')) 
            then substring-before($baseRngName, 'Mod') 
            else $baseRngName"
     />
    <!-- Handle OASIS special cases for module names.
         (files misnamed according to the file naming conventions)
    -->
    <xsl:variable name="entityNamePart" as="xs:string"
        select="if ('mapGroupDomain' = $baseEntityNamePart)
                   then 'mapGroup'
                   else $baseEntityNamePart
                   "
    />
    <xsl:variable name="entFilename" as="xs:string" 
      select="
      concat($entityNamePart, '.', $entityType)" 
    />
    <xsl:sequence select="$entFilename"/>
  </xsl:function>

  <xsl:function name="rngfunc:getGrammarUri" as="xs:string">
    <xsl:param name="rngGrammar" as="element(rng:grammar)"/>
    <xsl:variable name="result" select="if (document-uri(root($rngGrammar))) 
              then document-uri(root($rngGrammar))
              else $rngGrammar/@origURI"/>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getDomainsAttValue" as="xs:string?">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:variable name="domainsAttValue" as="xs:string?"
      select="$grammar//rng:attribute[@name = 'domains']/@a:defaultValue"
    />
    <xsl:if test="not($domainsAttValue)">
      <xsl:message> - [WARN] rngfunc:getDomainsAttValue(): Did not find an attribute declaration for an attribute named "domains".</xsl:message>
    </xsl:if>
    <xsl:sequence select="$domainsAttValue"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getDomainsContribution" as="xs:string*">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:variable name="domainValue" as="xs:string*" 
      select="for $value in $grammar/dita:moduleDesc/dita:moduleMetadata/dita:domainsContribution return $value"/>
    <xsl:sequence select="$domainValue"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isMixedContent" as="xs:boolean">
    <!-- The element parameter is the normalized element with all
         references expanded.
      -->
    <xsl:param name="element" as="element(rng:element)"/>
    <xsl:variable name="result" as="xs:boolean" 
      select="boolean($element//rng:text) or boolean($element//rng:ref[@name = 'any'])"/>
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getStartElementsForExternalRef" as="xs:string*">
    <xsl:param name="externalRef" as="element(rng:externalRef)"/>
    <xsl:sequence select="rngfunc:getStartElementsForExternalRef($externalRef, false())"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getStartElementsForExternalRef" as="xs:string*">
    <xsl:param name="externalRef" as="element(rng:externalRef)"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="moduleUri" as="xs:string" 
      select="$externalRef/ancestor-or-self::*[@origURI != ''][1]/@origURI"
    />
    
    <xsl:variable name="moduleResolvedUri" select="resolve-uri($externalRef/@href, $moduleUri)"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElementsForExternalRef(): moduleResolvedUri="<xsl:value-of select="$moduleResolvedUri"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="targetGrammar" as="document-node()?"
      select="document($moduleResolvedUri)"
    />
    <xsl:if test="not($targetGrammar)">
      <xsl:message> - [ERROR] getStartElementsForExternalRef(): Failed to resolve reference to external grammar usin g URI "<xsl:value-of select="$externalRef/@href"/>" against base URI "<xsl:value-of select="base-uri($externalRef)"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElementsForExternalRef(): Applying templates in mode getStartElements  to target grammar...</xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string*">
      <xsl:apply-templates select="$targetGrammar" mode="getStartElements">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElementsForExternalRef(): result="<xsl:sequence select="$result"/>"</xsl:message>
    </xsl:if>
    
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <!-- =======================================
       Mode getStartElements 
       ======================================= -->
  
  <xsl:template mode="getStartElements" match="/">
    <!-- FIXME: Apply the merge process to the root grammar and then analyze that -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: Matched on "/"</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="//rng:start | //rng:include" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: rng:include, href="<xsl:value-of select="@href"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="targetGrammar" as="document-node()?"
      select="document(string(@href), .)"
    />
    <xsl:if test="not($targetGrammar)">
      <xsl:message> - [ERROR] getStartElements: Failed to resolve reference to external grammar usin g URI "<xsl:value-of select="./@href"/>" against base URI "<xsl:value-of select="base-uri(.)"/>"</xsl:message>
    </xsl:if>
    
    <xsl:apply-templates mode="#current" select="$targetGrammar"/>
    
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="rng:start">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: rng:start: <xsl:sequence select="."/></xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="rng:ref" >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="targetName" as="xs:string" select="@name"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: rng:ref: targetName="<xsl:sequence select="$targetName"/>"</xsl:message>
      <xsl:message> + [DEBUG]   count(//rng:define[@name = $targetName][.//rng:element])=<xsl:sequence select="count(//rng:define[@name = $targetName][.//rng:element])"/>"</xsl:message>
    </xsl:if>
    <xsl:apply-templates select="//rng:define[@name = $targetName][.//rng:element]" mode="#current"/>
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: rng:define: name="<xsl:sequence select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:apply-templates mode="#current" select=".//rng:element"/>
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="rng:element">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="tagName" as="xs:string"
      select="if (@name) then @name else string(name)"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] getStartElements: rng:element: tagName="<xsl:sequence select="$tagName"/>"</xsl:message>
    </xsl:if>
    <xsl:sequence select="$tagName"/>
  </xsl:template>
  
  <xsl:template mode="getStartElements" match="node()" priority="-1">
    
  </xsl:template>
  
  <xsl:function name="rngfunc:getModulePackage" as="xs:string">
    <!-- Given a grammar module document, determines the package it belongs to. -->
    <xsl:param name="grammarDoc" as="document-node()"/>
    <!-- The OASIS file organization scheme is package/rng/foo.rng
         so the package is the grandparent directory name.
      -->
    <xsl:variable name="pathTokens" as="xs:string*"
      select="tokenize(base-uri($grammarDoc/*), '/')"
    />
    <xsl:variable name="result" as="xs:string"
      select="$pathTokens[last() - 2]"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isShellGrammar" as="xs:boolean">
    <xsl:param name="doc" as="document-node()"/>
    
    <!-- NOTE: For now ignoring ditaval.rng as it is a special case.
         Will need to handle it specially at some point. Or not.
      -->
    <xsl:variable name="result" as="xs:boolean"
      select="rngfunc:getModuleType($doc/*, false()) = ('topicshell', 'mapshell')"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isModuleDoc" as="xs:boolean">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="base-uri" 
      as="xs:string"
      select="string(base-uri($doc/*))"
    />
    <xsl:variable name="filename" as="xs:string"
      select="relpath:getName($base-uri)"
    />
    <!-- FIXME: Need to use the module metadata, not the filename. 
         See issue #12
      -->
    <xsl:variable name="result" as="xs:boolean"
      select="ends-with($filename, 'Mod.rng')
              "
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isExtendedModule" as="xs:boolean">
    <!-- Returns true if the candidate module declares a top-level element
         extended by any other module in the list of modules. This check
         is based on looking for patterns that end with "-{tagname}", where
         "tagname" is the name of an element type defined in one of the 
         element-type-name patterns defined in the candidate module.
      -->
    <xsl:param name="candModule" as="document-node()">
      <!-- The candidate module. -->
    </xsl:param>
    <xsl:param name="domainModules" as="document-node()*">
      <!-- The domain modules that may extend types in the candidate module.
           This list should not include the candidate module itself.
      -->
    </xsl:param>
    <xsl:sequence select="rngfunc:isExtendedModule($candModule, $domainModules, false())"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:isExtendedModule" as="xs:boolean">
    <!-- Returns true if the candidate module declares a top-level element
         extended by any other module in the list of modules. This check
         is based on looking for patterns that end with "-{tagname}", where
         "tagname" is the name of an element type defined in one of the 
         element-type-name patterns defined in the candidate module.
      -->
    <xsl:param name="candModule" as="document-node()">
      <!-- The candidate module. -->
    </xsl:param>
    <xsl:param name="domainModules" as="document-node()*">
      <!-- The domain modules that may extend types in the candidate module.
           This list should not include the candidate module itself.
      -->
    </xsl:param>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <!-- The list for metaDecl is hard coded because the patterns are
         defined in the commonElementsMod.rng, reflecting the original
         DTD design.
      -->
    <xsl:variable name="metaDeclTopLevelTypes" as="xs:string*"
      select="(
      'audience',
      'author',
      'brand',
      'category',
      'component',
      'copyrholder',
      'copyright',
      'copyryear',
      'created',
      'critdates',
      'featnum',
      'keywords',
      'metadata',
      'othermeta',
      'permissions',
      'platform',
      'prodinfo',
      'prodname',
      'prognum',
      'publisher',
      'resourceid',
      'revised',
      'series',
      'source',
      'vrm',
      'vrmlist'
      )"
    />
    
    <!-- The tag names of top-level element types defined in the candidate module: -->
    <xsl:variable name="top-level-types" as="xs:string*"
      select="if (rngfunc:getModuleShortName($candModule/*) = 'metaDecl')
                 then $metaDeclTopLevelTypes
                 else $candModule/*/rng:define[rng:ref[ends-with(@name, '.element')]]/@name"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] isExtendedModule(): top-level-types=<xsl:sequence select="$top-level-types"/></xsl:message>
    </xsl:if>
    <!-- Domain extension patterns declared in any domain module: -->
    <xsl:variable name="domainExtensionPatternNames" as="xs:string*"
      select="$domainModules//rng:define[starts-with(@name, rngfunc:getModuleShortName(root(.)/*))]/@name"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] isExtendedModule(): domainExtensionPatternNames=<xsl:sequence
          select="$domainExtensionPatternNames"/></xsl:message>
    </xsl:if>
    
    <xsl:variable name="topLevelNames" as="xs:string*"
      select="distinct-values(for $name in $domainExtensionPatternNames return tokenize($name, '-')[last()])"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] isExtendedModule(): topLevelNames=<xsl:sequence
        select="$topLevelNames"/></xsl:message>
    </xsl:if>
    
    <!-- List comparisons are true if any item in the left-hand list occurs in the right-hand list. -->
    <xsl:variable name="result" as="xs:boolean" 
      select="$top-level-types = $topLevelNames"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] isExtendedModule(): Returning <xsl:sequence
        select="$result"/></xsl:message>
    </xsl:if>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <xsl:function name="rngfunc:isConstrainedModule" as="xs:boolean">
    <!-- Returns true if the candidate module is constrained by any
         constraint modules.
      -->
    <xsl:param name="candModule" as="document-node()">
      <!-- The candidate module. -->
    </xsl:param>
    <xsl:param name="constraintModules" as="document-node()*">
      <!-- The constraint modules that may constrain the candidate
           module.
      -->
    </xsl:param>
    
    <xsl:variable name="constrainedModuleNames" as="xs:string*"
      select="for $grammar in $constraintModules[rngfunc:isConstraintModule(.)]/* 
                  return for $include in $grammar//rng:include 
                         return relpath:getName(string($include/@href))"
    />
    <xsl:variable name="thisModuleName" as="xs:string"
      select="relpath:getName(rngfunc:getGrammarUri($candModule/*))"
    />
    <xsl:variable name="result" as="xs:boolean" 
      select="$thisModuleName = $constrainedModuleNames"/>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  <xsl:function name="rngfunc:isStandardModule" as="xs:boolean">
    <!-- Returns true if the candidate module is a TC-defined module.
      -->
    <xsl:param name="candModule" as="document-node()">
      <!-- The candidate module. -->
    </xsl:param>
    
    <xsl:variable name="idType" as="xs:string"
      select="if (ends-with(rngfunc:getModuleType($candModule/*), 'shell'))
                 then 'rngShell'
                 else 'rngMod'"
    />
    
    <xsl:variable name="result" as="xs:boolean"
      select="starts-with(rngfunc:getPublicId($candModule/*, $idType),
                       'urn:oasis:names:tc:')"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <!-- Returns the set of module documents reflecting the modules
       directly or indirectly included by the starting grammar (e.g.,
       a document type shell.
       
       NOTE: This returns *all* included modules, including base
       modules. rngfunc:getIncludedModules() excludes topic and map
       modules and thus base modules included by them.
       
       For XSD generation, we have to handle all the modules because
       of how overrides work.
    -->
  <xsl:function name="rngfunc:getIncludedModuleDocs" as="document-node()*">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:sequence select="rngfunc:getIncludedModuleDocs($grammar, false())"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getIncludedModuleDocs" as="document-node()*">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="result" as="document-node()*">
      <xsl:for-each select="$grammar//rng:include">
        <xsl:if test="$doDebug">
          <xsl:message> + [DEBUG] rngfunc:getIncludedModuleDocs(): Include of "<xsl:value-of select="@href"/>"</xsl:message>
        </xsl:if>
        <xsl:variable name="module" select="document(@href,.)"/>
        <xsl:choose>
          <xsl:when test="$module">            
            <xsl:if test="$doDebug">
              <xsl:message> + [DEBUG] rngfunc:getIncludedModuleDocs(): including module "<xsl:value-of select="rngfunc:getModuleShortName($module/*)"/>"</xsl:message>
            </xsl:if>
            <xsl:sequence select="$module"/>            
            <xsl:sequence  select="rngfunc:getIncludedModuleDocs($module/*, $doDebug)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message> - [WARN] rngfunc:getIncludedModules(): Failed to resolve URI "<xsl:value-of select="@href"/>" to a module.</xsl:message>
            <xsl:message> - [WARN]    Base URI = "<xsl:value-of select="base-uri(.)"/>"</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
 
  <!-- Returns the set of rng:grammar elements reflecting the modules
       directly or indirectly included by the starting grammar (e.g.,
       a document type shell.
    -->
  <xsl:function name="rngfunc:getIncludedModules" as="element(rng:grammar)*">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:sequence select="rngfunc:getIncludedModules($grammar, false())"/>
  </xsl:function>
  
  <xsl:function name="rngfunc:getIncludedModules" as="element(rng:grammar)*">
    <xsl:param name="grammar" as="element(rng:grammar)"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="result" as="element()*">
      <xsl:for-each select="$grammar//rng:include">
        <xsl:variable name="module" select="document(@href,.)"/>
        <xsl:choose>
          <xsl:when test="$module">
            <xsl:if test="
              rngfunc:isElementDomain($module) or 
              rngfunc:isAttributeDomain($module)  or
              rngfunc:isConstraintModule($module)  or
              (rngfunc:isTypeModule($module) and 
              not(rngfunc:getModuleShortName($module/*) = ('topic', 'map')))">
              <xsl:sequence select="$module/*"/>
            </xsl:if>
            <xsl:sequence  select="rngfunc:getIncludedModules($module/*, $doDebug)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message> - [WARN] rngfunc:getIncludedModules(): Failed to resolve URI "<xsl:value-of select="@href"/>" to a module.</xsl:message>
            <xsl:message> - [WARN]    Base URI = "<xsl:value-of select="base-uri(.)"/>"</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="$result"/>
    
  </xsl:function>
  
  
  <!-- ==========================================
        String formatting functions
        ========================================== -->
  
   <!-- See http://markmail.org/message/fhbwfe67amcjoelm?q=xslt+printf+list:com%2Emulberrytech%2Elists%2Exsl-list&page=1 -->
  
 <xsl:function name="str:pad" as="xs:string">
   <!-- Pad a string with len trailing characters -->
   <xsl:param    name="str" as="xs:string"/>
   <xsl:param    name="len" as="xs:integer"/>
   <xsl:variable name="lstr" select="string-length($str)" as="xs:integer"/>
   <xsl:choose>
     <xsl:when test="$lstr lt $len">
       <xsl:variable name="pad"
                     select="string-join((for $i in 1 to $len - $lstr return ' '),'')"/>
       <xsl:sequence select="concat($str,$pad)"/>  
     </xsl:when>
     <xsl:otherwise>
       <xsl:sequence select="$str"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:function>

 <xsl:function name="str:indent" as="xs:string">
   <!-- Generate a sequence of blanks of the specified length -->
   <xsl:param    name="len" as="xs:integer"/>
   <xsl:variable name="indent"
                 select="string-join((for $i in 1 to $len return ' '),'')"/>
   <xsl:sequence select="$indent"/>  
 </xsl:function>


</xsl:stylesheet>