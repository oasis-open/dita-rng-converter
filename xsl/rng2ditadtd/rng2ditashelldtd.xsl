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
  expand-text="yes"
  version="3.0"
  >

  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p>RNG to DITA DTD Converter</xd:p>
      <xd:p><xd:b>Created on:</xd:b> Feb 16, 2013</xd:p>
      <xd:p><xd:b>Authors:</xd:b> ekimber, pleblanc</xd:p>
      <xd:p>This transform takes as input RNG-format DITA document type
      shells and produces from them the DTD shell that
        that reflects the RNG definitions and conforms to the DITA 1.3
        DTD coding requirements.
      </xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:include href="mode-entityDeclaration.xsl"/>
  
  <!-- ================================================================= 
       Root processing template for individual RNG document type shells.
       ================================================================= -->
  
  <xsl:template mode="processShell" match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdOutputDir" as="xs:string" tunnel="yes"/>
    <xsl:param name="modulesToProcess"  tunnel="yes" as="document-node()*" />
    
    <!-- The base directory under which all output will be generated. This
         implements the organizational structure of the OASIS-provided modules,
         such that all generated files reflect the same relative locations
         as for the RNG modules.
      -->
    <!-- For OASIS modules, any shell will be in rng/{package}/rng
         The output needs to be in dtd/{package}/dtd
      -->
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] processShell: Handling doc {document-uri(root(.))} ("{base-uri(root(.)/*)}")</xsl:message>
      <xsl:message>+ [DEBUG] Initial process: Found {count($modulesToProcess)} modules.</xsl:message>
    </xsl:if>
        
    <xsl:variable name="rngShellUrl" as="xs:string"
      select="string(base-uri(root(.)))" />
    <xsl:variable name="packageName" as="xs:string" 
      select="relpath:getName(relpath:getParent(relpath:getParent($rngShellUrl)))"
    />
    <xsl:variable name="dtdFilename" as="xs:string"
      select="concat(relpath:getNamePart($rngShellUrl), '.dtd')" />
    <xsl:variable name="dtdResultUrl"
      select="relpath:toUrl(relpath:newFile(relpath:newFile(relpath:newFile($dtdOutputDir, $packageName), 'dtd'), $dtdFilename))" 
    />
    
    <xsl:variable name="referencedModulesBase" as="document-node()*">
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] processShell: Applying templates in mode "getReferencedModules"...</xsl:message>
      </xsl:if>
      
      <xsl:apply-templates select="." mode="getReferencedModules">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="modulesToProcess" as="document-node()*" tunnel="yes"
          select="$modulesToProcess" 
        />        
      </xsl:apply-templates>
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] processShell: Apply templates done.</xsl:message>
      </xsl:if>
    </xsl:variable>
    
    <!-- If there are multiple constraint modules for a given base module (for example,
         because there is a chain of constraint modules) then there will be multiple
         instances of the referenced module in referencedModulesBase so we need
         to reduce this list to a single item for each module.
      -->
    <xsl:variable name="referencedModules" as="document-node()*">
      <xsl:for-each-group select="$referencedModulesBase" group-by="base-uri(./*)">
        <xsl:sequence select="."/>
      </xsl:for-each-group>
    </xsl:variable>
    
    <!-- Get the set of all notAllowed patterns. This will be used to remove references
         to those patterns from any context that would otherwise refer to them. This is
         in support of constraints that use notAllowed to effectively remove element types,
         attributes, or other patterns.
      -->
    
    <xsl:variable name="notAllowedPatterns" as="element(rng:define)*"
      select="(., $referencedModules)//rng:define[rng:notAllowed]"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] referencedModules: {$referencedModules ! rngfunc:getModuleShortName(./*) => string-join(', ')}</xsl:message>
    </xsl:if>
    
    <xsl:variable name="notAllowedPatternNames" as="xs:string*"
      select="$notAllowedPatterns/@name ! string(.)"
    />       
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] processShell: Not allowed patterns:</xsl:message>
      <xsl:for-each-group select="$notAllowedPatterns" group-by="base-uri(.)">
        <xsl:message>+ [DEBUG]  Module {current-grouping-key()}:</xsl:message>
        <xsl:for-each select="current-group()">
          <xsl:message>+ [DEBUG]   - {@name}</xsl:message>
        </xsl:for-each>
      </xsl:for-each-group>
      <xsl:message>+ [DEBUG] processShell: notAllowedPatternNames: {$notAllowedPatternNames => string-join(', ')}</xsl:message>
    </xsl:if>

    <xsl:variable name="referencedModulesNoDivs" as="document-node()*"
      select="
        $referencedModules[
        ($doGenerateStandardModules) or
        not(rngfunc:isStandardModule(.))
        ]
      "
    />
    <xsl:variable name="referencedModulesFiltered" as="document-node()*">
      <xsl:apply-templates select="$referencedModulesNoDivs" mode="filter-notallowed-patterns">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="notAllowedPatternNames" as="xs:string*" tunnel="yes" select="$notAllowedPatternNames"/>
      </xsl:apply-templates>
    </xsl:variable>

    <shell>
      <inputDoc><xsl:sequence select="base-uri(root(.))"></xsl:sequence></inputDoc>
      <xsl:choose>
        <xsl:when test="count(rng:grammar/*)=1 and rng:grammar/rng:include">
          <!--  simple redirection, as in technicalContent/glossary.dtd -->
            <redirectedTo>
              <xsl:value-of select="concat(substring-before(rng:grammar/rng:include/@href,'.rng'),'.dtd')" />
            </redirectedTo>
        </xsl:when>
        <xsl:otherwise>
          <dtdFile><xsl:sequence select="$dtdResultUrl" /></dtdFile>
  
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- Generate the .dtd file: -->
        
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] / applying templates in mode dtdFile. $dtdOutputDir="<xsl:sequence select="$dtdOutputDir"/>", rngShellUrl="{$rngShellUrl}"</xsl:message>
      </xsl:if>
      <xsl:result-document href="{$dtdResultUrl}" format="dtd">
        <xsl:apply-templates mode="dtdFile">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="dtdFilename" select="$dtdFilename" tunnel="yes" as="xs:string" />
          <xsl:with-param name="dtdOutputDir" select="$dtdOutputDir" tunnel="yes" as="xs:string" />
          <xsl:with-param name="modulesToProcess"  select="$referencedModules" tunnel="yes" as="document-node()*" />
          <xsl:with-param name="referencedModulesFiltered" tunnel="yes" as="document-node()*" select="$referencedModulesFiltered"/>
          <xsl:with-param name="referencingGrammarUrl" select="$rngShellUrl" tunnel="yes" as="xs:string"/>
          <xsl:with-param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*" select="$notAllowedPatterns"/>
          <xsl:with-param name="notAllowedPatternNames" tunnel="yes" as="xs:string*" select="$notAllowedPatternNames"/>
        </xsl:apply-templates>
      </xsl:result-document>
        
    </shell>

  </xsl:template>
  


  <!-- ==============================
       .dtd file generation mode
       ============================== -->

  <xsl:template match="rng:grammar" mode="dtdFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="dtdOutputDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    <xsl:param name="referencedModulesFiltered" tunnel="yes" as="document-node()*"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>    
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] dtdFile: rng:grammar: dtdDir="<xsl:sequence select="$dtdOutputDir"/>"</xsl:message>
    </xsl:if>    
    <xsl:variable name="firstStart" as="element()?"
      select="(//rng:start/rng:ref)[1]"
    />
    <xsl:variable name="rootElement" 
      select="substring-before($firstStart/@name,'.element')" 
      as="xs:string" />
    
    <xsl:message>+ [INFO] === Generating DTD shell {$dtdFilename}...</xsl:message>
    
    
    <xsl:variable name="shellType" select="rngfunc:getModuleType(.)" as="xs:string"/>
    
    <xsl:if test="$shellType != 'topicshell' and $shellType != 'mapshell'">
      <xsl:message terminate="no"> - [ERROR] mode dtdFile: Expected module type 'topicshell' or 'mapshell', got "<xsl:sequence select="$shellType"/>".</xsl:message>
    </xsl:if>
    
    <!-- ====================================
         Start generating the shell DTD file:
         ==================================== -->
    
    <xsl:text>&lt;?xml version="1.0" encoding="UTF-8"?>&#x0a;</xsl:text>

    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='dtdShell'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
    />
    
    <xsl:choose>
      <xsl:when test="$shellType='mapshell'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                MAP ENTITY DECLARATIONS                        -->
&lt;!-- ============================================================= -->
</xsl:text>
      </xsl:when>
      <xsl:when test="$shellType='topicshell'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--              TOPIC ENTITY DECLARATIONS                        -->
&lt;!-- ============================================================= -->
</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] dtdFile: grammar - moduleShortName="<xsl:sequence select="rngfunc:getModuleShortName(.)"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <!-- The base topic and map modules are special cases in that they have no
           corresponding .ent file.
        -->
      <xsl:when test="count(*)=1 and rng:include">
        <!--  simple redirection, as in technicalContent\glossary.dtd -->
        <xsl:apply-templates mode="dtdRedirect" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates 
          select="$modulesToProcess[rngfunc:getModuleType(*) = ('topic', 'map')]" 
          mode="entityDeclaration" >
          <xsl:with-param 
            name="entityType" 
            select="'ent'" 
            as="xs:string" 
            tunnel="yes"
          />
          <!-- FIXME: Determine if we should be using document-uri() or base-uri() here. -->
          <xsl:with-param name="rngShellUri" as="xs:string"
            select="document-uri(root(.))"
          />
        </xsl:apply-templates>
        <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--             DOMAIN CONSTRAINT INTEGRATION                     -->
&lt;!-- ============================================================= -->
</xsl:text>
        
        <xsl:variable name="domainConstraintModules" as="document-node()*"
          select="$modulesToProcess[rngfunc:isDomainConstraintModule(.)]"
        />
        <xsl:message>+ [INFO]    Domain constraint modules to integrate: {$domainConstraintModules/* ! rngfunc:getModuleShortName(.) => string-join(', ')}</xsl:message>
        <xsl:apply-templates 
          select="$domainConstraintModules" 
          mode="entityDeclaration" 
          >
          <xsl:with-param 
            name="entityType" 
            select="'mod'" 
            as="xs:string" 
            tunnel="yes"
          />
        </xsl:apply-templates>
        
        
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--             DOMAIN ENTITY DECLARATIONS                        -->
&lt;!-- ============================================================= -->
</xsl:text>

        <xsl:apply-templates 
          select="$modulesToProcess[rngfunc:getModuleType(*) = 'elementdomain']" 
          mode="entityDeclaration" 
        >
          <xsl:with-param 
            name="entityType" 
            select="'ent'" 
            as="xs:string" 
            tunnel="yes"
          />
        </xsl:apply-templates>

<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--             DOMAIN ATTRIBUTES DECLARATIONS                    -->
&lt;!-- ============================================================= -->
</xsl:text>

        <xsl:apply-templates 
          select="$modulesToProcess[rngfunc:getModuleType(*) = 'attributedomain']" 
          mode="entityDeclaration" 
        >
          <xsl:with-param 
            name="entityType" 
            select="'ent'" 
            as="xs:string" 
            tunnel="yes"
          />
        </xsl:apply-templates>


<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN EXTENSIONS                          -->
&lt;!-- ============================================================= -->
&lt;!--                    One for each extended base element, with
                        the name of the domain(s) in which the
                        extension was declared                     -->
</xsl:text>
        <!-- Get the set of element domain modules then get the set of 
             domain extension patterns from all of them and from
             any constraint modules then process that set to generate one parameter 
             entity for each unique element type being extended.
             
             Constraint modules will override the domain extension
             patterns for the domain modules they override (as 
             generated during the notAllowed filtering process).
             
             Note: No space between declarations within this group.
          -->
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] dtdFile: rng:grammar - Generating domain extension integration
            entities... </xsl:message>
        </xsl:if>
        
        <xsl:variable name="domainModules" as="element(rng:grammar)*"
          select="$modulesToProcess[rngfunc:isElementDomain(.)]/*"
        />
        <xsl:variable name="constraintModules" as="element(rng:grammar)*"
          select="$referencedModulesFiltered[rngfunc:isDomainConstraintModule(.)]/*"
        />
        <xsl:message>+ [INFO] Domain modules to integrate: {$domainModules !
          rngfunc:getModuleShortName(.) => string-join(', ')}</xsl:message>
        <xsl:message>+ [INFO] Domain constraint modules to integrate: {$constraintModules !
          rngfunc:getModuleShortName(.) => string-join(', ')}</xsl:message>
        
        <xsl:variable name="baseDomainExtensionPatterns" as="element(rng:define)*"
          select="
          ($domainModules | $constraintModules)//
          rng:define[not(@name = $notAllowedPatternNames)][starts-with(@name, rngfunc:getModuleShortName(root(.)/*))]
          "
        />
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG]  baseDomainExtensionPatterns:
            <xsl:sequence select="$baseDomainExtensionPatterns ! rngfunc:report-element(.)"/>        
          </xsl:message>
        </xsl:if>
        
        <!-- Set of domain extension patterns from base domain modules or from domain constraint
             modules. This excludes any patterns that empty or notAllowed.
          -->
        <xsl:variable name="domainExtensionPatterns" as="element(rng:define)*">
          <xsl:call-template name="get-domain-extension-patterns">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="dtdFilename" select="$dtdFilename"/>
            <xsl:with-param name="baseDomainExtensionPatterns" select="$baseDomainExtensionPatterns"/>
          </xsl:call-template>
        </xsl:variable>                
        
        <xsl:if test="$doDebug">
          <!--      <xsl:message>+ [DEBUG] notAllowed patterns: {$notAllowedPatternNames => string-join(', ')} </xsl:message>-->
          <xsl:message>+ [DEBUG] domainExtension patterns: {$domainExtensionPatterns/@name =>
            string-join(', ')} </xsl:message>
        </xsl:if>
        
        <xsl:message>+ [INFO] Generating domain extension entities from domain extension patterns...</xsl:message>
        
        <xsl:for-each-group select="$domainExtensionPatterns"
          group-by="substring-after(@name, concat(rngfunc:getModuleShortName(root(.)/*), '-'))">
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG]   notAllowedPatternNames:
{$notAllowedPatternNames => distinct-values() => sort() => string-join(', ')}
</xsl:message>
          </xsl:if>
          
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] current-grouping-key="{current-grouping-key()}"</xsl:message>
          </xsl:if>
          
          <xsl:variable name="base-element-pattern-name" select="current-grouping-key() || '.element'"/>
          <xsl:variable name="baseIsAllowed" as="xs:boolean"
            select="not($base-element-pattern-name = $notAllowedPatternNames)"
          />      
          <xsl:variable name="allowed-patterns" as="element(rng:define)*"
            select="current-group()[not(@name = $notAllowedPatternNames) and empty(rng:empty | rng:notAllowed)]"
          />
          <xsl:variable name="declaration-tokens" as="xs:string*"
            select="
              (if ($baseIsAllowed) then current-grouping-key() else (),
               $allowed-patterns/@name ! ('%' || . || ';')
              )
            "
          />
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG]   base-element-pattern-name="{$base-element-pattern-name}"</xsl:message>
            <!--        <xsl:message>+ [DEBUG] notAllowed patterns: {$notAllowedPatternNames => string-join(', ')} </xsl:message>-->
            <xsl:message>+ [DEBUG]   baseIsAllowed="{$baseIsAllowed}"</xsl:message>
            <xsl:message>+ [DEBUG]   allowed-patterns="{$allowed-patterns/@name ! string(.) => string-join(', ')}"
             {$allowed-patterns ! rngfunc:report-element(.) => string-join('&#x0a;')}      
            </xsl:message>
          </xsl:if>
          <xsl:if test="empty($allowed-patterns)">
            <xsl:message>- [ERROR] Domain extension entity "%{$base-element-pattern-name}": Base element
              "{current-grouping-key()}" is not allowed and</xsl:message>
            <xsl:message>- [ERROR] no other patterns are allowed. Effective value will be "" (empty
              string), which is not valid for DTD syntax.</xsl:message>
            <xsl:message>- [ERROR] Either set the entire pattern to notAllowed, allow the base element
              type, or allow at least one specialization of the base.</xsl:message>
          </xsl:if>
          
          <xsl:variable name="firstPart" as="xs:string"
            select="concat('&#x0a;&lt;!ENTITY % ', current-grouping-key())"/>
          <xsl:text>
            {$firstPart}{
              if (string-length($firstPart) lt 26)
              then str:indent(25 - string-length($firstPart))
              else ' '
            }"</xsl:text>
          <xsl:if test="exists($allowed-patterns)">
            <xsl:variable name="sep" as="xs:string" select="concat(' |', '&#x0a;', str:indent(25))"/>
            <xsl:text>{$declaration-tokens => string-join($sep)}&#x0a;{str:indent(24)}</xsl:text>
          </xsl:if>
          <xsl:text>"&gt;</xsl:text>
        </xsl:for-each-group>
        <xsl:text>&#x0a;</xsl:text>
        
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN ATTRIBUTE EXTENSIONS                -->
&lt;!-- ============================================================= -->

</xsl:text>
<!--
<!ENTITY % props-attribute-extensions  
  ""
>
<!ENTITY % base-attribute-extensions   
  ""
>       
-->          
        <xsl:variable name="domainModules" as="element()*"
          select="$modulesToProcess[rngfunc:isAttributeDomain(.)]/*" 
        />
        <!-- ====== @props extensions ============ -->
        <xsl:variable name="propsExtensionPatterns" as="element()*"
          select="$domainModules//rng:define[@name = 'props-attribute-extensions']"
        />
<xsl:text>&lt;!ENTITY % props-attribute-extensions&#x0a;</xsl:text>
<xsl:text>  "</xsl:text>
        <xsl:for-each-group select="$propsExtensionPatterns" group-by="@name">
            <!-- Here the referenced attribute group becomes the name of the entity 
                 we want to reference. There should be exactly one <rng:ref> element
                 within this <define>:
                 
  <define name="props-attribute-extensions" combine="interleave">
    <ref name="deliveryTargetAtt-d-attribute"/>
  </define>

              -->
            <xsl:variable name="entityName" as="xs:string"
              select="rng:ref/@name"
            />
          <xsl:value-of select="concat('%', $entityName, ';', 
            if (position() != last()) then concat('&#x0a;', str:indent(3)) else '')"/>
        </xsl:for-each-group>
<xsl:text>"&#x0a;&gt;&#x0a;</xsl:text>
        
        <!-- ====== @base extensions ============ -->
        <xsl:variable name="baseExtensionPatterns" as="element()*"
          select="$domainModules//rng:define[@name = 'base-attribute-extensions']"
        />
<xsl:text>&lt;!ENTITY % base-attribute-extensions&#x0a;</xsl:text>
<xsl:text>  "</xsl:text>
        <xsl:for-each-group select="$baseExtensionPatterns" group-by="@name">
            <!-- Here the referenced attribute group becomes the name of the entity 
                 we want to reference. There should be exactly one <rng:ref> element
                 within this <define>:
                 
  <define name="base-attribute-extensions" combine="interleave">
    <ref name="deliveryTargetAtt-d-attribute"/>
  </define>

              -->
            <xsl:variable name="entityName" as="xs:string"
              select="rng:ref/@name"
            />
          <xsl:value-of select="concat('%', $entityName, ';', 
            if (position() != last()) then concat('&#x0a;', str:indent(3)) else '')"/>
        </xsl:for-each-group>
<xsl:text>"&#x0a;&gt;&#x0a;</xsl:text>
        
<xsl:if test="rngfunc:getModuleType(.) = 'topicshell'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    TOPIC NESTING OVERRIDE                     -->
&lt;!-- ============================================================= -->
&#x0a;</xsl:text>
        
    <!-- The *-info-types pattern will always be defined in the topic module
         but may also be overridden in the reference to the module. Thus,
         for each reference to a topic module we have to see what the effective
         definition for the {topictype}-info-types pattern is and use it
         here.
         
         The override may also be in a reference to a constraint module, so
         need to check that to (e.g., strict taskbody constraint).
      -->
        <xsl:variable name="topicModuleIncludes" as="element()*">
          <xsl:for-each select=".//rng:include">
            <xsl:variable name="module" select="document(@href,.)"/>
            <xsl:choose>
              <xsl:when test="$module">
                <xsl:if test="./rng:define[ends-with(@name , 'info-types')] or 
                              rngfunc:getModuleType($module/*) = 'topic'">
                  <xsl:sequence select="."/>
                </xsl:if>              
              </xsl:when>
              <xsl:otherwise>
                <xsl:message>+ [WARN] Failed to resolve reference to URI "{@href}, relative to base URI
"{base-uri(.)}"</xsl:message>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] match="rng:grammar" mode="dtdFile": count(topicModuleIncludes)="{count($topicModuleIncludes)}"</xsl:message>
        </xsl:if>
        
        <xsl:for-each select="$topicModuleIncludes">          
          <xsl:choose>
            <xsl:when test=".//rng:define">
              <xsl:if test="$doDebug">
                <xsl:message>+ [DEBUG] match="rng:grammar" mode="dtdFile": Found defines, processing them...</xsl:message>
              </xsl:if>
              <xsl:apply-templates select=".//rng:define" mode="generate-parment-decl-from-define"/>              
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="$doDebug">
                <xsl:message>+ [DEBUG] match="rng:grammar" mode="dtdFile": No defines, generating *-info-types declaration...</xsl:message>
              </xsl:if>
              <xsl:variable name="module" select="document(./@href,.)" as="document-node()"/>
              <xsl:variable name="topicType" as="xs:string" select="rngfunc:getModuleShortName($module/*)"/>
              <!-- The topic module is always included and we don't want to 
                   reflect its -info-types pattern (because it's always just "topic").
                   
                   However, for shells that are configuring <topic>, we do want it.
                -->
              <xsl:if test="$topicType != 'topic' or (normalize-space(//rng:start/rng:ref/@name) = 'topic.element')">
                <xsl:if test="$doDebug">
                  <xsl:message>+ [DEBUG] match="rng:grammar" mode="dtdFile": A topic-type module, applying templates to *-info-types defines...</xsl:message>
                  <xsl:message>+ [DEBUG]  info-types defines in {document-uri($module)} ("{base-uri($module/*)}"):
                    <xsl:sequence select="$module//rng:define[ends-with(@name, '-info-types')]"/>
                  </xsl:message>
                </xsl:if>
                <xsl:apply-templates 
                  select="$module//rng:define[ends-with(@name, '-info-types')]"
                  mode="handle-info-types-pattern"
                />                
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
</xsl:if>
        <!-- Only the ditabase doctype has a locally-defined containment
             section.
          -->
        <xsl:if test="$rootElement = 'dita'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    LOCALLY DEFINED CONTAINMENT                -->
&lt;!-- ============================================================= -->
</xsl:text>
          <!-- WEK: For now just hard-coding this because it is invariant. -->
          <xsl:call-template name="handle-ditaelem-element-decl">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:call-template>
        </xsl:if>

<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAINS ATTRIBUTE OVERRIDE                 -->
&lt;!-- ============================================================= -->
</xsl:text>
        <xsl:variable name="includedModules" as="element(rng:grammar)*"
             select="rngfunc:getIncludedModules(., $doDebug)"
        />
        
        <xsl:text>&#x0a;&lt;!ENTITY included-domains&#x0a;</xsl:text>
        <xsl:value-of select="str:indent(26)"/>
        <xsl:text>"</xsl:text>
          <xsl:for-each select="$includedModules[not(rngfunc:getModuleType(.) = 'constraint')]">
            <xsl:if test="position() > 1">
              <xsl:value-of select="str:indent(27)"/>
            </xsl:if>
            <xsl:apply-templates select="." mode="generateDomainsContributionEntityReference"/>
          </xsl:for-each>
        <xsl:for-each select="$includedModules[rngfunc:getModuleType(.) = 'constraint']">
          <xsl:value-of select="str:indent(27)"/>
          <xsl:apply-templates select="." mode="generateDomainsContributionEntityReference"/>
        </xsl:for-each>
        <xsl:text>  "&#x0a;>&#x0a;</xsl:text>

<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    CONTENT CONSTRAINT INTEGRATION             -->
&lt;!-- ============================================================= -->
</xsl:text>
        <xsl:variable name="contentConstraintModules" as="document-node()*"
          select="$modulesToProcess[rngfunc:isContentConstraintModule(., $doDebug)]"
        />
        <xsl:message>+ [INFO]    Content constraint modules to integrate: {$contentConstraintModules/* ! rngfunc:getModuleShortName(.) => string-join(', ')}</xsl:message>
        <xsl:apply-templates 
          select="$contentConstraintModules" 
          mode="entityDeclaration" 
        >
          <xsl:with-param 
            name="entityType" 
            select="'mod'" 
            as="xs:string" 
            tunnel="yes"
          />
        </xsl:apply-templates>

        
    <xsl:choose>
      <xsl:when test="$shellType='mapshell'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                      MAP ELEMENT INTEGRATION                  -->
&lt;!-- ============================================================= -->
</xsl:text>
        <!-- The reference to the map.mod must always be first -->
         <xsl:apply-templates 
            select="$modulesToProcess[rngfunc:getModuleShortName(./*) = 'map']"
            mode="entityDeclaration"
          >
            <xsl:with-param 
              name="entityType" 
              select="'type'" 
              as="xs:string" 
              tunnel="yes"
            />
          </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$shellType='topicshell'">
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    TOPIC ELEMENT INTEGRATION                  -->
&lt;!-- ============================================================= -->
</xsl:text>
        <!-- The reference to the topic.mod must always be first -->
         <xsl:apply-templates 
            select="$modulesToProcess[rngfunc:getModuleShortName(./*) = 'topic']"
            mode="entityDeclaration"
          >
            <xsl:with-param 
              name="entityType" 
              select="'type'" 
              as="xs:string" 
              tunnel="yes"
            />
          </xsl:apply-templates>

      </xsl:when>
      <xsl:otherwise>
<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                       ELEMENT INTEGRATION                     -->
&lt;!-- ============================================================= -->
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
          <!-- For now special case the learningGroupMap and learningObjectMap modules,
               which depend on the learningMap domain and therefore
               needs to be included after that domain. 
               
               Need a more general way to manage the output of map
               and topic type modules that depend on domains.
            -->
          <xsl:apply-templates 
            select="$modulesToProcess[
            rngfunc:getModuleType(*) = ('topic', 'map') and 
            not(rngfunc:getModuleShortName(./*) = ('topic', 'map')) and
            not(rngfunc:getModuleShortName(./*) = ('learningGroupMap', 'learningObjectMap'))]"
            mode="entityDeclaration"
          >
            <xsl:with-param 
              name="entityType" 
              select="'type'" 
              as="xs:string" 
              tunnel="yes"
            />
          </xsl:apply-templates>
          

<xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                    DOMAIN ELEMENT INTEGRATION                 -->
&lt;!-- ============================================================= -->
</xsl:text>

        <xsl:apply-templates 
          select="$modulesToProcess[rngfunc:getModuleType(*) = 'elementdomain']" 
          mode="entityDeclaration" 
        >
          <xsl:with-param 
            name="entityType" 
            select="'mod'" 
            as="xs:string" 
            tunnel="yes"
          />
        </xsl:apply-templates>


      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:if test="rngfunc:getModuleShortName(.) = ('learningGroupMap', 'learningObjectMap')">
      <xsl:text>
&lt;!-- ============================================================= -->
&lt;!--                        ELEMENT INTEGRATION                    -->
&lt;!-- ============================================================= -->
</xsl:text>
      <!-- Special case for learningGroupMap. See above. -->
      <xsl:apply-templates 
        select="$modulesToProcess[
        rngfunc:getModuleType(*) = ('topic', 'map') and 
        not(rngfunc:getModuleShortName(./*) = ('topic', 'map')) and
        (rngfunc:getModuleShortName(./*) = ('learningGroupMap', 'learningObjectMap'))]"
        mode="entityDeclaration"
        >
        <xsl:with-param 
          name="entityType" 
          select="'type'" 
          as="xs:string" 
          tunnel="yes"
        />
      </xsl:apply-templates>
    </xsl:if>
    
    <xsl:if test="$rootElement = 'dita'">
      <xsl:call-template name="handle-ditaelem-attlist-decl">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:call-template>
    </xsl:if>  
    
    <xsl:text>
&lt;!-- ================= End of </xsl:text>
    <xsl:value-of select="rngfunc:getModuleTitle(.)"/>
    <xsl:text> ================= --></xsl:text>
    
    <xsl:message>+ [INFO] === DTD shell {$dtdFilename} generated.</xsl:message>

  </xsl:template>
  
  <!-- Gather the effective (not empty, not notAllowed) domain extension patterns
       from the domain and domain constraint modules.
    -->
  <xsl:template name="get-domain-extension-patterns">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="dtdFilename" as="xs:string"/>
    <xsl:param name="baseDomainExtensionPatterns"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] Constructing domainExtensionPatterns...</xsl:message>
    </xsl:if>
    <xsl:for-each-group select="$baseDomainExtensionPatterns" group-by="@name">
      <xsl:if test="$doDebug">
        <xsl:message>+ [DEBUG] grouping key: "{current-grouping-key()}"</xsl:message>
        <xsl:message>+ [DEBUG] Number of patterns: "{count(current-group())}"</xsl:message>
      </xsl:if>
      <xsl:variable name="candidate-pattern" as="element(rng:define)?">
        <xsl:choose>
          <xsl:when test="count(current-group()) gt 1">
            <xsl:if test="$doDebug">
              <xsl:message>+ [DEBUG] More than one pattern for name "{current-grouping-key()}",
                looking for constraint module version.</xsl:message>
            </xsl:if>
            <!-- There should be a constraint module version of the pattern. Get it -->
            <xsl:for-each select="current-group()">
              <xsl:if test="$doDebug">
                <xsl:message>+ [DEBUG] Pattern from {base-uri(.)}: <xsl:sequence
                    select="rngfunc:report-element(.)"/>
                </xsl:message>
              </xsl:if>
              <xsl:if test="rngfunc:isConstraintModule(root(.))">
                <xsl:if test="$doDebug">
                  <xsl:message>+ [DEBUG] Module is a constraint module, using this
                    version</xsl:message>
                </xsl:if>
                <!-- Use the constrained version -->
                <xsl:sequence select="."/>
              </xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="count(current-group()) eq 1">
            <xsl:if test="$doDebug">
              <xsl:message>+ [DEBUG] Exactly one pattern for name "{current-grouping-key()}" from
                module "{base-uri(.)}", using it.</xsl:message>
            </xsl:if>
            <xsl:sequence select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$doDebug">
              <xsl:message>+ [DEBUG] Current group is empty. This should not happen.</xsl:message>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="exists($candidate-pattern/rng:empty | $candidate-pattern/rng:notAllowed)">
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] Pattern "{$candidate-pattern/@name}" is empty or notAllowed,
              ignoring it.</xsl:message>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="$doDebug">
            <xsl:message>+ [DEBUG] Pattern "{$candidate-pattern/@name}" is not empty or notAllowed,
              using it.</xsl:message>
          </xsl:if>
          <xsl:sequence select="$candidate-pattern"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template mode="generateDomainsContributionEntityReference" match="rng:grammar">
    <xsl:variable name="attRef" as="xs:string"
      select="concat('&amp;', normalize-space(rngfunc:getModuleShortName(.)), '-att', ';', '&#x0a;')"
    />
    <xsl:sequence select="$attRef"/>
  </xsl:template>
  
  <xsl:template mode="generateDomainsContributionEntityReference" priority="5"
    match="rng:grammar[rngfunc:isConstraintModule(root(.))]" 
    >
    <xsl:value-of
      select="concat('&amp;', normalize-space(rngfunc:getModuleShortName(.)), '-constraints', ';', '&#x0a;')"
    />                            
  </xsl:template>
  
  <xsl:template name="handle-ditaelem-element-decl">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Context is the grammar for the shell. -->
    
    <!-- The <dita> element is a special case but the actual declarations are normal -->
    <xsl:text><![CDATA[
<!ELEMENT dita          (%info-types;)+                              >  
]]></xsl:text>
    <!-- NOTE: The attribute list declaration goes at the end of the
               shell so that all the entity references will resolve.
      -->
  </xsl:template>
  
  <xsl:template name="handle-ditaelem-attlist-decl">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:variable name="ditaAttlistDecl" as="element()*" 
      select=".//rng:define[@name = 'dita.attlist']"/>
    <xsl:variable name="indent" as="xs:integer" select="14"/>
    <xsl:text>
&lt;!ATTLIST dita&#x0a;</xsl:text>
    <xsl:if test="$ditaVersion = '1.3'">
      <xsl:value-of select="str:indent($indent)"/><xsl:text>domains 
                        CDATA                            
                                  "&amp;included-domains;"&#x0a;</xsl:text>    
    </xsl:if>
    <xsl:value-of select="str:indent($indent)"/>
    <xsl:apply-templates mode="element-decls" select="$ditaAttlistDecl/*">
      <xsl:with-param name="indent" 
        select="$indent" 
        as="xs:integer" 
        tunnel="yes"
      />
      <xsl:with-param name="isAttSet" as="xs:boolean" select="true()" tunnel="yes"/>
      <xsl:with-param name="tagname" tunnel="yes" as="xs:string"   select="'dita'"/>     
      <xsl:with-param name="domainPfx" as="xs:string" tunnel="yes" select="''"/>
    </xsl:apply-templates>
    <xsl:text>&#x0a;&gt;&#x0a;</xsl:text>    
        
  </xsl:template>

  <xsl:template match="rng:include" mode="dtdRedirect">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- FIXME: Should be able to put this through the generic entity
                reference code, but not 100% sure.
      -->
    <xsl:variable name="dtdRedirect" select="substring-before(@href,'.rng')" />
    <xsl:variable name="dtdDoc" select="document(@href)" as="document-node()" />
    <xsl:variable name="dtdPublicId" 
      select="rngfunc:getPublicId($dtdDoc/*, 'dtdMod', true())" />
    <xsl:text>&#x0a;&lt;!ENTITY % </xsl:text><xsl:value-of select="concat($dtdRedirect,'Dtd')" /> 
    <xsl:text>&#x0a;  PUBLIC "</xsl:text><xsl:value-of select="$dtdPublicId" /><xsl:text>" &#x0a;         "</xsl:text>
    <xsl:value-of select="concat($dtdRedirect,'.dtd')" />
    <xsl:text>"&#x0a;>&#x0a;%</xsl:text>
    <xsl:value-of select="concat($dtdRedirect,'Dtd')" /> 
    <xsl:text>;&#x0a;</xsl:text>
    
  </xsl:template>

  <xsl:template mode="handle-info-types-pattern" match="rng:define[ends-with(@name, '-info-types')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] handle-info-types-pattern: rng:define, name="{@name}"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="rng:ref[@name = 'info-types']">
        <!-- Don't output in the shell since it's not different from the base declaration -->        
      </xsl:when>
      <xsl:when test="rng:empty">
        <xsl:text>
&lt;!ENTITY % </xsl:text><xsl:value-of select="@name"/><xsl:text>&#x0a;</xsl:text>
        <xsl:text>"no-topic-nesting"&#x0a;
&gt;&#x0a;</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="generate-parment-decl-from-define" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*" mode="domainExtension">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" select="node()" />
  </xsl:template>

  <xsl:template match="*" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" select="node()" />
  </xsl:template>

  <xsl:template match="rng:zeroOrMore" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" />
    <xsl:text>)*</xsl:text>
    <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
  </xsl:template>

  <xsl:template match="rng:oneOrMore" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" />
    <xsl:text>)+</xsl:text>
    <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
  </xsl:template>

  <xsl:template match="rng:choice" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:for-each select="rng:*">
        <xsl:apply-templates select="." mode="#current" />
        <xsl:if test="not(position()=last())"><xsl:text> |&#x0a;</xsl:text></xsl:if>
    </xsl:for-each>
    <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
  </xsl:template>
  
  <xsl:template match="rng:optional" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates mode="#current" />
    <xsl:text>)?</xsl:text>
    <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
  </xsl:template>

  <xsl:template match="rng:define" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="rng:ref[@name='info-types']" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="refTarget" select="key('definesByName',@name)" />
    <xsl:if test="$refTarget">
       <xsl:apply-templates select="$refTarget/rng:*" mode="#current" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:ref[ends-with(@name,'.element')]" mode="nestingOverride">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:value-of select="substring-before(@name,'.element')" />
  </xsl:template>

  <xsl:template match="rng:ref" mode="dtdExtension domainExtension">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:text>%</xsl:text><xsl:value-of select="@name" /><xsl:text>; </xsl:text>
    <xsl:if test="not(position()=last())">
      <xsl:text>|</xsl:text>
    </xsl:if>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="rng:empty" mode="dtdExtension">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:comment> empty </xsl:comment>
  </xsl:template>

  <xsl:template match="*" mode="localDefinition">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current" select="node()" />
  </xsl:template>

  <xsl:template match="rng:element" mode="localDefinition">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="../rnga:documentation | rnga:documentation" />
    <!-- Element declaration -->
    <xsl:text>&lt;!ELEMENT  </xsl:text>
    <xsl:value-of select="@name" />
    <xsl:text>    </xsl:text>
    <xsl:variable name="subElements" select="rng:*[not(ends-with(@name, '.attlist'))]"/>
    <xsl:if test="count($subElements) &gt; 1 or local-name($subElements[1])='text'">
      <xsl:text>(</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="$subElements" mode="moduleFile" />
    <xsl:if test="count($subElements) &gt; 1 or local-name($subElements[1])='text'">
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text> &gt;&#x0a;</xsl:text>

    <xsl:if test="rng:ref[ends-with(@name, '.attlist')]">
      <xsl:variable name="refPointer" select="rng:ref[ends-with(@name, '.attlist')]" />
      <xsl:variable name="refTarget" select="key('definesByName',$refPointer/@name)" />
      <xsl:choose>
        <xsl:when test="not($refTarget)">
          <xsl:text>&lt;!ATTLIST  </xsl:text>
          <xsl:value-of select="@name" />
          <xsl:text>&#x0a;  </xsl:text>
          <xsl:apply-templates select="$refPointer" mode="moduleFile" />
          <xsl:text>&gt;&#x0a;&#x0a;</xsl:text>
        </xsl:when>
        <xsl:when test="$refTarget/rng:empty">
          <xsl:text>&#x0a;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="$refTarget/rnga:*" mode="moduleFile" />
          <xsl:text>&lt;!ATTLIST  </xsl:text>
          <xsl:value-of select="@name" />
          <xsl:text>&#x0a;  </xsl:text>
          <xsl:apply-templates select="$refTarget/rng:*" mode="moduleFile" />
          <xsl:text>&gt;&#x0a;&#x0a;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*" mode="dtdFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Most stuff we don't care about -->
  </xsl:template>

  <xsl:template match="rnga:documentation" mode="dtdFile" />

  <xsl:template match="comment()" mode="dtdFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Suppress comments in dtdFile mode -->
  </xsl:template>
  


</xsl:stylesheet>