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
  exclude-result-prefixes="xs xd rng rnga relpath a str dita rngfunc local rng2ditadtd"
  version="3.0">

  <!-- DITA RNG to XSD document type shell schema 
  
       Copyright (c) OASIS Open 2013, 2014     
  -->
  
  <!-- ================================================================= 
       Root processing template for individual RNG document type shells.
       ================================================================= -->
  
  <xsl:template mode="processShell" match="/">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="schemaOutputDir" as="xs:string" tunnel="yes"/>
    <xsl:param name="modulesToProcess"  tunnel="yes" as="document-node()*" />
    <!-- NOTE: modulesToProcess is all the modules included by all the shells
         being processed, not just the shell currently being processed.
      -->
    
    <xsl:variable name="rngShellUrl" as="xs:string"
      select="string(base-uri(root(.)))" />
    <xsl:variable name="packageName" as="xs:string" 
      select="relpath:getName(relpath:getParent(relpath:getParent($rngShellUrl)))"
    />
    <xsl:variable name="shellFilename" as="xs:string"
      select="concat(relpath:getNamePart($rngShellUrl), '.xsd')" />
    <xsl:variable name="shellResultUrl"
      select="relpath:newFile(relpath:newFile(relpath:newFile($schemaOutputDir, $packageName), 'xsd'), $shellFilename)" 
    />
    
    <xsl:variable name="isDitabase" as="xs:boolean"
      select="rngfunc:getModuleShortName(./*) = 'ditabase'"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processShell: / - Have <xsl:value-of select="count($modulesToProcess)"/> modules to process.</xsl:message>
    </xsl:if>
    
    <!-- For the Grp files we need to include all modules, top-level or nested.
      
         For the Mod files we need to only include the top-level inclusions.
         
      -->
    <xsl:variable name="referencedModules" as="document-node()*"
      select="rngfunc:getIncludedModuleDocs(./*, $doDebug)"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] processShell: / - Have <xsl:value-of select="count($referencedModules)"/> referenced modules.</xsl:message>
    </xsl:if>
    
    <shell>
      <inputDoc><xsl:sequence select="base-uri(root(.))"></xsl:sequence></inputDoc>
      <xsl:choose>
        <xsl:when test="count(rng:grammar/*)=1 and rng:grammar/rng:include">
          <!--  simple redirection, as in technicalContent/glossary.dtd -->
          <redirectedTo>
            <xsl:value-of select="concat(substring-before(rng:grammar/rng:include/@href,'.rng'),'.xsd')" />
          </redirectedTo>
        </xsl:when>
        <xsl:otherwise>
          <xsdShellFile><xsl:sequence select="$shellResultUrl" /></xsdShellFile>          
        </xsl:otherwise>
      </xsl:choose>
      
      <!-- Generate the .xsd file: -->
      
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] / applying templates in mode xsdFile. $schemaOutputDir="<xsl:sequence select="$schemaOutputDir"/>", rngShellUrl="<xsl:value-of select="$rngShellUrl"/>"</xsl:message>
      </xsl:if>
      <xsl:result-document href="{$shellResultUrl}" format="xsd">
        <xsl:apply-templates mode="xsdFile">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="xsdFilename" select="$shellFilename" tunnel="yes" as="xs:string" />
          <xsl:with-param name="xsdDir" select="$schemaOutputDir" tunnel="yes" as="xs:string" />
          <xsl:with-param name="modulesToProcess"  select="$referencedModules" tunnel="yes" as="document-node()*" />
          <xsl:with-param name="rngShellUrl" select="$rngShellUrl" tunnel="yes" as="xs:string"/>
          <xsl:with-param name="isDitabase" as="xs:boolean" tunnel="yes"
            select="$isDitabase"
          />
        </xsl:apply-templates>
      </xsl:result-document>
      <xsl:if test="$doGenerateModules and $isDitabase">
        <!-- Generate ditabaseMod.xsd 
             
             Note that this separate ditabase module only exists for the XSD, there is 
             not one for DTDs and thus not one for RELAX NG.
         -->
        <xsl:call-template name="makeDitabaseMod">
          <xsl:with-param name="moduleUri" as="xs:string"
            select="relpath:newFile(relpath:newFile(relpath:newFile($schemaOutputDir, $packageName), 'xsd'),
                     'ditabaseMod.xsd')" 
          />
          
        </xsl:call-template>
      </xsl:if>
      
    </shell>
    
  </xsl:template>
  
  <xsl:template match="rng:grammar" mode="xsdFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="xsdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*" />
    <!-- NOTE: Here, modulesToProcess is the set of modules referenced by the current
               shell, not the set of all modules being processed.
      -->
    <xsl:param name="isDitabase" tunnel="yes" as="xs:boolean" />
    
<!--    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
    
    <!-- Generate an XSD shell for a map or topic type -->
    
    <xsl:message> + [INFO] === Generating XSD shell <xsl:value-of select="$xsdFilename" />...</xsl:message>
    
    <xsl:variable name="shellType" select="rngfunc:getModuleType(.)" as="xs:string"/>
    
    <xsl:if test="$shellType != 'topicshell' and $shellType != 'mapshell'">
      <xsl:message terminate="yes"> - [ERROR] mode xsdFile: Expected module type 'topicshell' or 'mapshell', got "<xsl:sequence select="$shellType"/>".</xsl:message>
    </xsl:if>
        
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] xsdFile: rng:grammar: Have <xsl:value-of select="count($modulesToProcess)"/> modules to process.</xsl:message>
    </xsl:if>
    
    <!-- Generate the header comment -->
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='xsdShell'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
    >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
<!--    <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
    
    <xs:schema 
      xmlns:xs="http://www.w3.org/2001/XMLSchema" 
      elementFormDefault="qualified" 
      attributeFormDefault="unqualified" 
      >
      <xsl:namespace name="ditaarch">http://dita.oasis-open.org/architecture/2005/</xsl:namespace>      
      <xsl:if test="rngfunc:getModuleType(.) = 'topicshell'">      
        <xsl:text>&#x0a;</xsl:text>
        <xsl:comment> ================ TOPIC DOMAINS ===================== </xsl:comment>
        <xsl:text>&#x0a;</xsl:text>
      </xsl:if>      
      <!-- FIXME: The last not() term may not be right: not sure why call to isConstrainedModule for the 
                  set of domain modules.
        -->
      <xsl:if test="rngfunc:getModuleType(.) = 'mapshell'">
        <xsl:variable name="mapMod" as="document-node()?"
          select="$modulesToProcess[(rngfunc:getModuleShortName(./*) = 'map')][rngfunc:getModuleType(./*) = 'map']"
        />
        <xsl:message> + [DEBUG] mapshell: mapMod.rng is in modulesToProcess: <xsl:value-of select="boolean($mapMod)"/></xsl:message>
        <xsl:if test="$mapMod">
          <xsl:message> + [DEBUG]     mapMod is extended: <xsl:value-of 
            select="rngfunc:isExtendedModule($mapMod, ($modulesToProcess except $mapMod))"/></xsl:message>
        </xsl:if>
      </xsl:if>
      <xsl:apply-templates 
        mode="generateIncludes"
        select="$modulesToProcess[rngfunc:isAttributeDomain(.) or rngfunc:isElementDomain(.) and
                                  not(rngfunc:isExtendedModule(., ($modulesToProcess except .))) and
                                  not(rngfunc:isConstrainedModule(.,
                                      ($modulesToProcess[rngfunc:isConstraintModule(.)])))]"
        >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="fileType" select="'mod'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> ================ GROUP DEFINITIONS ===================== </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
      
      <xsl:variable name="includedModules" as="document-node()*"
          select="rngfunc:getIncludedModuleDocs(., $doDebug)"
      />
            
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] **** shell handling, before metaDecl: included modules:
        <xsl:for-each select="$includedModules">
          <xsl:sequence select="'&#x0a;', document-uri(.)"/> <xsl:text>("</xsl:text> <xsl:value-of select="base-uri(./*)"/><xsl:text>")</xsl:text>
        </xsl:for-each>
        </xsl:message>
      </xsl:if>

      
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] generating include for metaDecl.</xsl:message>
      </xsl:if>
      
      <!-- The tbl and metaDecl group modules are included before the the topic ones. --> 
      
      <xsl:if test="not(rngfunc:isExtendedModule($includedModules[rngfunc:getModuleShortName(./*) = 'metaDecl'],
                                                 ($includedModules except .),
                                                 $doDebug))">
        <xsl:if test="$doDebug">
          <xsl:message> + [DEBUG]  metaDecl is not extended, generating xs:include...</xsl:message>
        </xsl:if>
        <xsl:apply-templates 
          mode="generateIncludes"
          select="$includedModules[rngfunc:getModuleShortName(./*) = 'metaDecl']" 
          >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="fileType" select="'grp'" as="xs:string" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:message> + [DEBUG] generating include for tblDecl..</xsl:message>
      <xsl:if test="not(rngfunc:isExtendedModule($includedModules[rngfunc:getModuleShortName(./*) = 'tblDecl'],
        ($includedModules except .)))">
        <xsl:apply-templates 
        mode="generateIncludes"
        select="$includedModules[rngfunc:getModuleShortName(./*) = 'tblDecl']" 
        >
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="fileType" select="'grp'" as="xs:string" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates 
        mode="generateIncludes"
        select="$includedModules[rngfunc:getModuleType(./*) = ('topic', 'map')]
                                [not(rngfunc:isExtendedModule(., ($includedModules except .)))]" 
        >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="fileType" select="'grp'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> =================  MODULE INCLUDE DEFINITION  ================== </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>

      <xsl:apply-templates 
        mode="generateIncludes"
        select="$includedModules[rngfunc:getModuleShortName(./*) = 'commonElements']" 
        >
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="fileType" select="'mod'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>

      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> ======== Table elements ======== </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>

      <xsl:apply-templates select="$includedModules[rngfunc:getModuleShortName(./*) = 'tblDecl']" mode="generateIncludes">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="fileType" select="'mod'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> ======= MetaData elements, plus keyword and indexterm ======= </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
  
      <xsl:apply-templates select="$includedModules[rngfunc:getModuleShortName(./*) = 'metaDecl']" mode="generateIncludes">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="fileType" select="'mod'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
  
  
  <xsl:text>&#x0a;</xsl:text>
      
      <!-- Generate domain extension redefines (redefines of commonElements, metaDecl, tblDecl) -->    
  <xsl:call-template name="generateRedefines">
    <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    <xsl:with-param name="modulesToProcess" select="$includedModules" as="document-node()*"/>
  </xsl:call-template>
  <xsl:text>&#x0a;</xsl:text>
  <xsl:text>&#x0a;</xsl:text>
      
  <!-- Now generate includes or redefines of topic or map modules and 
       constraint modules. If a constraint module references
       a module then that module should not be included
       here as it will be included by the constraint module.
       
       The XSD pattern for constraints is essentially the same
       as the RNG pattern in terms of how modules are referenced.
       
    -->
      
  
  <xsl:choose>
    <xsl:when test="$shellType = 'topicshell'">
            
      <xsl:text>&#x0a;</xsl:text>
      
      <xsl:if test="not($isDitabase)">
        <xsl:apply-templates select=".//rng:include" mode="handleTopLevelIncludes">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
        
      </xsl:if>
            
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment>  ================ INFO-TYPES DEFINITION =====================  </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
      
      <xsl:choose>
        <!-- Get the set of top-level included modules: -->
        <xsl:when test="$isDitabase">
          <xsl:variable name="topLevelModules" as="document-node()*">
            <xsl:apply-templates select="." mode="getReferencedModules">
              <xsl:with-param name="origModule" select="root(.)" as="document-node()" tunnel="yes"/>
              <xsl:with-param name="modulesToProcess" as="document-node()*" tunnel="yes"
                select="$includedModules" 
              />
              <!-- For shells we only care about the modules directly referenced from the shell -->
              <xsl:with-param name="isProcessNestedIncludes" as="xs:boolean" tunnel="yes" select="false()"/>          
            </xsl:apply-templates>
          </xsl:variable>      
          <xsl:call-template name="generate-ditabase-includes">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="topLevelModules" as="document-node()*" select="$topLevelModules"/>
            <xsl:with-param name="modulesToProcess" as="document-node()*" tunnel="yes"
              select="$includedModules" 
            />
          </xsl:call-template>
          
        </xsl:when>
        <xsl:otherwise>
          <xs:group name="info-types">
            <xs:annotation>
              <xs:documentation>
This group is referenced in all topic modules but not defined there.
It must be declared in topic-type shells.
</xs:documentation>
            </xs:annotation>
            <xs:choice>
              <xs:element ref="no-topic-nesting" maxOccurs="0" minOccurs="0"/>
            </xs:choice>    
          </xs:group>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text>&#x0a;</xsl:text>
    </xsl:when>
    <xsl:when test="$shellType = 'mapshell'">
      <xsl:apply-templates select=".//rng:include" mode="handleTopLevelIncludes">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="." mode="topLevelIncludesExtensions">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      <xsl:text>&#x0a;</xsl:text>
    </xsl:when>
     <xsl:otherwise>
        <!-- Not a map or topic shell -->
     </xsl:otherwise>
   </xsl:choose>
            
  <!-- Maps and topics both declare the @domains attribute: -->
      <xsl:text>&#x0a;</xsl:text>
      <xs:attributeGroup name="domains-att">
        <xs:attribute name="domains" type="xs:string" 
                                default="{normalize-space(rngfunc:getDomainsAttValue(.))}"/>
      </xs:attributeGroup>
    
    </xs:schema>
  </xsl:template>  
  
  <xsl:template mode="handleTopLevelIncludes" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"></xsl:param>
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleTopLevelIncludes: include of <xsl:value-of select="@href"/></xsl:message>
    </xsl:if>
    
    <!-- NOTE: As far as I can figure out there's no easy way to determine whether
         a given include of a given module needs to be a redefine: it depends
         on the modifications (or lack thereof) to the *-info-types group,
         any extensions to domain-defined groups for non-base-type elements,
         etc.
         
         So the basic approach is to have the default be a simple include and
         use overrides for each known case.
      -->
    
    <xsl:variable name="includedRNGModule" as="document-node()?"
      select="document(@href, root(.))"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleTopLevelIncludes: Module type=<xsl:value-of select="rngfunc:getModuleType($includedRNGModule/*)"/></xsl:message>
    </xsl:if>
    
    <xsl:if test="rngfunc:getModuleType($includedRNGModule/*) = ('topic', 'map', 'constraint')">
      <xsl:variable name="xsdUri" as="xs:string"
        select="local:constructModuleSchemaLocation($includedRNGModule/*, 'mod', $xsdDir, $rngShellUrl)"
      />
      <xs:include schemaLocation="{$xsdUri}">
        <xsl:apply-templates select="a:documentation" mode="handleDocumentation"/>
      </xs:include>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="handleDocumentation" match="a:documentation">
    <xs:annotation>
      <xs:documentation><xsl:apply-templates mode="documentation"/></xs:documentation>
    </xs:annotation>
  </xsl:template>
    
  <xsl:template name="generate-ditabase-includes">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"></xsl:param>
    <xsl:param name="topLevelModules" as="document-node()*"/>
    <xsl:param name="modulesToProcess" as="document-node()*" tunnel="yes"/>
    
    <!-- Challenge here is to distinguish unconstrained topic types from 
               constrained topic types and only generate redefines for the 
               constraining module when the topic type is constrained.
               
            -->
    
    <xsl:apply-templates mode="ditabase-topicmod-includes"
      select="$topLevelModules[rngfunc:getModuleType(./*) = ('topic', 'constraint')]"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <xsl:variable name="ditabaseModUri" as="xs:string"
      select="
      if ($doUseURNsInShell) 
      then 'urn:oasis:names:tc:dita:xsd:ditabaseMod.xsd' 
      else 'ditabaseMod.xsd'"
    />
    <xs:include schemaLocation="{$ditabaseModUri}"/>
    
    <xs:group name="ditabase-info-types">
      <xs:choice>
        <xs:group ref="info-types"/>
      </xs:choice>
    </xs:group>
    
    <xs:group name="info-types">
      <xs:choice>
        <xsl:for-each select="$modulesToProcess[rngfunc:getModuleType(./*) = 'topic']">
          <xs:element ref="{rngfunc:getModuleShortName(./*)}"/>
        </xsl:for-each>
      </xs:choice>
    </xs:group>
  </xsl:template>
  
  <xsl:template name="generateRedefines">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" as="document-node()*"/>
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
        
  <!-- Get the set of element domain modules then get the set of 
       domain extension patterns from all of them then process
       that set to generate one redefine group for each unique
       element type being extended.       
    -->
        
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateRedefines(): Have <xsl:value-of select="count($modulesToProcess)"/> modules to process.</xsl:message>
    </xsl:if>
    <xsl:message> + [INFO] Generating domain extension redefines... </xsl:message>
    <xsl:variable name="domainModules" as="element()*"
      select="$modulesToProcess[rngfunc:isElementDomain(.) or rngfunc:isAttributeDomain(.)]/*" 
    />
    <xsl:message> + [INFO] Domain modules to integrate: <xsl:sequence select="for $mod in $domainModules return rngfunc:getModuleShortName($mod)"/></xsl:message>

    <xsl:variable name="domainExtensionPatterns" as="element()*"
      select="$domainModules//rng:define[starts-with(@name, rngfunc:getModuleShortName(root(.)/*))]"
    />
    
    <!-- Domain elements extend element types defined in one of the base modules (commmentElements, 
         metaDecl, tblDecl) or the map or topic module (mapMod, topicMod) or in other domains (e.g.,
         learningInteractionBase2 is extended by the learningDomain2).
         
         For each of these modules find the set of extension patterns from all the other modules.
         If this set is not empty, generate a redefine for the module.
         
      -->
    
    <xsl:for-each 
      select="$modulesToProcess[rngfunc:getModuleType(./*) = ('base') or
               (rngfunc:getModuleType(*/.) = ('topic', 'map', 'elementdomain') and
                rngfunc:isExtendedModule(., ($modulesToProcess except .)))
      ]">
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] generateRedefines: Constructing xs:redefine for module "<xsl:value-of select="rngfunc:getModuleShortName(./*)"/>"</xsl:message>
      </xsl:if>
      <!-- Element domains do not have Grp modules. -->
      <xsl:variable name="moduleUri" as="xs:string"
        select="local:getModuleUri(
                                    if (rngfunc:getModuleType(*/.) = 'elementdomain') 
                                       then 'Mod' 
                                       else 'Grp', 
                                    ., 
                                    $xsdDir, $rngShellUrl)"
      />      
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] generateRedefines: mdouleUri="<xsl:value-of select="$moduleUri"/>"</xsl:message>
      </xsl:if>
      
      <xsl:variable name="rngModuleUrl" as="xs:string"
        select="if (*/@origURI) then */@origURI else base-uri(.)"
      />
      <xsl:variable name="origModule" as="document-node()"
        select="document($rngModuleUrl)"
      />
      
      <!-- FIXME: This is a lot of nested for-eaches and whatnot. Probably better
                  implemented as templates.
        -->

      <!-- Now get the list of element type pattern names defined in the base module: -->
      <xsl:variable name="elementTypeNames" as="xs:string*">
        <xsl:sequence 
          select="for $elem in $origModule//rng:element
                      return string($elem/@name)
          "
        />
      </xsl:variable>
      <xsl:variable name="attributeExtensionGroups" as="xs:string*">
        <xsl:sequence 
          select="for $elem in $origModule//rng:define[ends-with(@name, '-attribute-extensions')]
          return string($elem/@name)
          "
        />
      </xsl:variable>
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] generateRedefines: elementTypeNames=<xsl:sequence select="$elementTypeNames"/></xsl:message>
      </xsl:if>
      <xsl:variable name="elementExtensionDefines" as="node()*">
        <xsl:for-each select="$modulesToProcess[rngfunc:getModuleType(./*) = ('elementdomain')]">
          <xsl:variable name="groupNamePrefix" as="xs:string"
            select="concat(rngfunc:getModuleShortName(./*), '-')"
          />
          <xsl:sequence 
            select=".//rng:define[substring-after(@name, $groupNamePrefix) = $elementTypeNames]"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="attributeExtensionDefines" as="node()*">
        <xsl:for-each select="($modulesToProcess[rngfunc:getModuleType(./*) = ('attributedomain')])">
          <xsl:sequence 
            select=".//rng:define[string(@name) = $attributeExtensionGroups]"/>
        </xsl:for-each>
      </xsl:variable>
      
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] generateRedefines: elementExtensionDefines=<xsl:sequence select="for $define in $elementExtensionDefines return string($define/@name)"/></xsl:message>
        <xsl:message> + [DEBUG] generateRedefines: attributeExtensionDefines=<xsl:sequence select="for $define in $attributeExtensionDefines return string($define/@name)"/></xsl:message>
      </xsl:if>
      
      <xsl:if test="count($elementExtensionDefines) > 0 or 
                    count($attributeExtensionDefines) > 0"
        >
        <xsl:apply-templates select="." mode="generateRedefineElement">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="rngShellUrl" tunnel="yes" as="xs:string" select="$rngShellUrl"/>
          <xsl:with-param name="moduleUri" as="xs:string" select="$moduleUri"/>
          <xsl:with-param name="elementTypeNames" as="xs:string*" select="$elementTypeNames"/>
          <xsl:with-param name="elementExtensionDefines" as="node()*" select="$elementExtensionDefines"/>
          <xsl:with-param name="attributeExtensionDefines" as="node()*" select="$attributeExtensionDefines"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:for-each>

  </xsl:template>
  
  <xsl:template mode="generateRedefineElement" match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="moduleUri" as="xs:string"/>
    <xsl:param name="elementTypeNames" as="xs:string*"/>
    <xsl:param name="elementExtensionDefines" as="node()*"/>
    <xsl:param name="attributeExtensionDefines" as="node()*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateRedefines: Constructing xs:redefine for <xsl:value-of select="$moduleUri"/></xsl:message>
    </xsl:if>
    <xs:redefine schemaLocation="{$moduleUri}">
      <xsl:for-each select="$elementTypeNames">
        <xsl:variable name="endsWithKey" as="xs:string" select="concat('-', .)"/>
        <xsl:variable name="extensions" as="node()*"
          select="$elementExtensionDefines[ends-with(@name, $endsWithKey)]"
        />
        <xsl:if test="count($extensions) > 0">
          <xs:group name="{.}">
            <xs:choice>
              <xs:group ref="{.}"/>
              <xsl:for-each select="$extensions">
                <xs:group ref="{./@name}"/>
              </xsl:for-each>
            </xs:choice>
          </xs:group>              
        </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="('props-attribute-extensions', 'base-attribute-extensions')">
        <xsl:variable name="defineName" as="xs:string" select="."/>
        <xsl:if test="$attributeExtensionDefines[@name = $defineName]">
          <xs:attributeGroup name="{$defineName}">
            <xs:attributeGroup ref="{$defineName}"/><!-- This is a bit of XSD mojo. See XSD document-type shell: Coding requirements in the Arch Spec -->
            <xsl:for-each select="$attributeExtensionDefines[@name = $defineName]/rng:ref">
              <xs:attributeGroup ref="{@name}"/>
            </xsl:for-each>
          </xs:attributeGroup>
        </xsl:if>
      </xsl:for-each>
    </xs:redefine>  
  </xsl:template>
  
  <xsl:template match="/" mode="generateIncludes">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="rng:grammar" mode="generateIncludes">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param 
      name="fileType" 
      as="xs:string" 
      tunnel="yes"
    /><!-- One of "mod" or "grp"  
      
    -->
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
    <xsl:param name="isDitabase" tunnel="yes" as="xs:boolean" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateIncludes: rng:grammar "<xsl:value-of select="rngfunc:getModuleShortName(.)"/>"</xsl:message>
      <xsl:message> + [DEBUG] generateIncludes:   fileType="<xsl:value-of select="$fileType"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="schemaLocation" as="xs:string"
      select="local:constructModuleSchemaLocation(., $fileType, $xsdDir, $rngShellUrl)"
      />
    
    <!-- NOTE: For XSD we can't just blindly use redefine to set the *-info-types group: if the
         group is redefined in the RNG.
         
         For example, concept.rng has this declaration:
         
          <include href="conceptMod.rng">
            <define name="concept-info-types">
              <ref name="concept.element"/>
            </define>
          </include>
          
          For DTDs, the correct result is:
          
          <!ENTITY % concept-info-types
              "concept"
          >
          
          However, for XSD, if you had:
          
          <xs:redefine schemaLocation="./conceptMod.xsd">
             <xs:group name="concept-info-types">
               <xs:choice>
                 <xs:group ref="concept-info-types"/>
                 <xs:element ref="concept"/>
               </xs:choice>
             </xs:group>
           </xs:redefine>
           
           The content model is ambiguous (and invalid) because
           the base concept-info-types already includes element
           "concept".
           
           So for XSD the correct redefine is:
           
           <xs:redefine schemaLocation="./conceptMod.xsd">
             <xs:group name="concept-info-types">
               <xs:choice>
                 <xs:group ref="concept-info-types"/>
               </xs:choice>
             </xs:group>
           </xs:redefine>

           Which is the same as no redefine (but logically equivalent to the
           RNG and DTD).
           
           Only in the case where the redefinition includes elements not
           in the base would they need to be included in the redefine.
           
           For DITA 1.2 the only shell that actually needs a redefine
           is learningContent: all other shells do not change the
           base topic nesting definition. However, the original 1.2 XSD
           construction omitted from the XSD redefines that had no
           practical effect.

      -->
    <xs:include schemaLocation="{$schemaLocation}"/>        
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>
  
  <!-- ===============================
       Mode ditabase-topicmod-includes
       =============================== -->

  <xsl:template mode="ditabase-topicmod-includes"
    match="rng:grammar"
    >
    <xsl:param name="xsdDir" as="xs:string" tunnel="yes"/>
    <xsl:param name="rngShellUrl" as="xs:string" tunnel="yes"/>

    <xsl:variable name="schemaLocation" as="xs:string"
      select="local:constructModuleSchemaLocation(., 'Mod', $xsdDir,$rngShellUrl)"
    />
    <!-- Default: just use info-types -->
    
    <xsl:variable name="shortName" as="xs:string"
      select="local:constructInfoTypesName(.)"
    />
    <xs:redefine schemaLocation="{$schemaLocation}">      
      <xs:group name="{$shortName}-info-types">
        <xs:choice>
          <xs:group ref="info-types"/>
        </xs:choice>
      </xs:group>
    </xs:redefine>
    
  </xsl:template>
  
  <xsl:function name="local:constructInfoTypesName" as="xs:string">
    <xsl:param name="context" as="element(rng:grammar)"/>
    <!-- For constraint modules, use the @domains value to get the name
         of the topic type being constrained.
      -->
    <xsl:variable name="result" as="xs:string" 
      select="if (rngfunc:getModuleType($context) = 'constraint')
      then tokenize(rngfunc:getDomainsContribution($context), ' ')[last() - 1]
      else rngfunc:getModuleShortName($context)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <!-- ===============================
       End Mode ditabase-topicmod-includes
       =============================== -->
  
  
  <xsl:template name="makeDitabaseMod">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="moduleUri" as="xs:string"/>
    
    <xsl:result-document href="{$moduleUri}">
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
        elementFormDefault="qualified"
        attributeFormDefault="unqualified" >
        <xsl:namespace name="ditaarch">http://dita.oasis-open.org/architecture/2005/</xsl:namespace>
        
        <xs:import namespace="http://www.w3.org/XML/1998/namespace"  />
        <xs:import namespace="http://dita.oasis-open.org/architecture/2005/" schemaLocation="urn:oasis:names:tc:dita:xsd:ditaarch.xsd:1.2"/>
        
        <xs:annotation>
          <xs:documentation>The &lt;<keyword>dita</keyword>&gt; element provides a top-level container
            for multiple topics when you create documents using the ditabase XSD. The
            &lt;<keyword>dita</keyword>&gt; element lets you create any sequence of concept,
            task, and reference topics, and the ditabase XSD lets you further nest these
            topic types inside each other. The &lt;<keyword>dita</keyword>&gt; element has
            no particular output implications; it simply allows you to create multiple
            topics of different types at the same level in a single document.</xs:documentation>
        </xs:annotation>
        <xs:element name="dita" type="dita.class"/>
        <xs:complexType name="dita.class">
          <xs:choice maxOccurs="unbounded">
            <xs:group ref="ditabase-info-types"/>
          </xs:choice>
          <xs:attribute ref="ditaarch:DITAArchVersion"/>
          <xsl:choose>
            <xsl:when test="$ditaVersion = '1.3'">
              <xs:attributeGroup ref="localization-atts"/>
            </xsl:when>
            <xsl:otherwise>
              <xs:attribute ref="xml:lang"/>
            </xsl:otherwise>
          </xsl:choose>
          <xs:attributeGroup ref="global-atts"/>
        </xs:complexType>
        
      </xs:schema>
    </xsl:result-document>
  </xsl:template>

  <xsl:function name="local:getModuleUri" as="xs:string">
    <!-- Get the XSD URI for a module referenced from a shell or constraint module -->
    <xsl:param name="moduleType" as="xs:string"/><!-- 'Grp', or 'Mod' -->
    <xsl:param name="moduleDoc" as="document-node()"/><!-- Module being referenced -->
    <xsl:param name="xsdDir" as="xs:string"/><!-- XSD output directory -->
    <xsl:param name="rngShellUrl" as="xs:string"/><!-- URI of the referencing RNG module -->
    <xsl:sequence select="local:getModuleUri(
      $moduleType,
      $moduleDoc, 
      $xsdDir, 
      $rngShellUrl, 
      false())"/>
  </xsl:function>
  
  <xsl:function name="local:constructModuleSchemaLocation" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:param name="fileType" as="xs:string"/>
    <xsl:param name="xsdDir" as="xs:string"/>
    <xsl:param name="rngShellUrl" as="xs:string"/>
    
    <xsl:variable name="moduleSystemID" as="xs:string"
      select="local:getXsdUrlForRngModule($context, $fileType, $xsdDir, $rngShellUrl)"
    />
    
    <xsl:variable name="pubidTagname" as="xs:string"
      select="concat('xsd', if ($fileType = 'grp') then 'Grp' else 'Mod')"
    />
    <xsl:variable name="publicId" 
      select="rngfunc:getPublicId($context, $pubidTagname, true())" 
    />
    
    <xsl:variable name="schemaLocation" as="xs:string"
      select="if ($doUseURNsInShell)
      then $publicId
      else $moduleSystemID
      "
    />
    <xsl:sequence select="$schemaLocation"/>
  </xsl:function>
  
  
  <xsl:function name="local:getModuleUri" as="xs:string">
    <!-- Get the XSD URI for a module referenced from a shell or constraint module -->
    <xsl:param name="moduleType" as="xs:string"/><!-- 'Grp', or 'Mod' -->
    <xsl:param name="moduleDoc" as="document-node()"/><!-- Module being referenced -->
    <xsl:param name="xsdDir" as="xs:string"/><!-- XSD output directory -->
    <xsl:param name="rngShellUrl" as="xs:string"/><!-- URI of the referencing RNG module -->
    <xsl:param name="doDebug" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$doUseURNsInShell">
        <xsl:variable name="pubidTagname" as="xs:string"
          select="concat('xsd', $moduleType)"
        />
        <xsl:sequence  
          select="rngfunc:getPublicId($moduleDoc/*, $pubidTagname, true())" 
        />            
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$doDebug">
          <xsl:message> + [DEBUG] local:getModuleUri(): rngShellUrl="<xsl:value-of select="$rngShellUrl"/>"</xsl:message>
        </xsl:if>
        <xsl:sequence 
          select="local:getXsdUrlForRngModule(
                      $moduleDoc/*, 
                      lower-case($moduleType), 
                      $xsdDir, 
                      $rngShellUrl,
                      $doDebug)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:getXsdUrlForRngModule" as="xs:string">
    <xsl:param name="rngModule" as="element(rng:grammar)"/>
    <xsl:param name="fileType" as="xs:string"/><!-- One of "mod" or "grp" -->  
    <xsl:param name="xsdDir" as="xs:string" />
    <xsl:param name="rngShellUrl" as="xs:string"/>
    <xsl:sequence select="local:getXsdUrlForRngModule(
      $rngModule,
      $fileType,
      $xsdDir,
      $rngShellUrl,
      false()
      )"/>
  </xsl:function>
  
  <xsl:function name="local:getXsdUrlForRngModule" as="xs:string">
    <xsl:param name="rngModule" as="element(rng:grammar)"/>
    <xsl:param name="fileType" as="xs:string"/><!-- One of "mod" or "grp" -->  
    <xsl:param name="xsdDir" as="xs:string" />
    <xsl:param name="rngShellUrl" as="xs:string"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    
    <xsl:variable name="rngShellParent" as="xs:string" select="relpath:getParent($rngShellUrl)"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] local:getXsdUrlForRngModule: rngShellParent="<xsl:value-of select="$rngShellParent"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="rngModuleUrl" as="xs:string" select="rngfunc:getGrammarUri($rngModule)"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] local:getXsdUrlForRngModule: rngModuleUrl="<xsl:value-of select="$rngModuleUrl"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="rngModuleName" as="xs:string" select="relpath:getNamePart($rngModuleUrl)"/>
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
    <xsl:variable name="targetFilename" as="xs:string" select="
      if ($fileType = 'grp') 
        then $grpFilename 
        else $modFilename"
    />
    <xsl:variable name="relpathFromShell" as="xs:string" select="relpath:getParent(relpath:getRelativePath($rngShellParent, $rngModuleUrl))"/>
    <!-- FIXME: The replace is a short-term hack to avoid figuring out how to
                generalize the code for getting the result URI for a module
                so we can construct the relative output path properly.
                This hack will work for OASIS files but not necessarily 
                any other organization pattern.
      -->
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] local:getXsdUrlForRngModule: relpathFromShell="<xsl:value-of select="$relpathFromShell"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="moduleSystemID" as="xs:string" 
      select="replace(relpath:newFile($relpathFromShell, $targetFilename), '/rng/', '/xsd/')"/>
    <xsl:variable name="finalSystemID" as="xs:string"
      select="if (not(contains($moduleSystemID, '/'))) 
                 then concat('./', $moduleSystemID) 
                 else $moduleSystemID"
    />
    <xsl:sequence select="$finalSystemID"/>
  </xsl:function>

</xsl:stylesheet>