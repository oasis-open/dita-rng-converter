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
  version="2.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jan 31, 2014</xd:p>
      <xd:p><xd:b>Author:</xd:b> ekimber</xd:p>
      <xd:p>Handles generation of the *Mod.xsd and *Grp.xsd files from
      their corresponding RelaxNG module.</xd:p>
      <xd:p>Structural modules and the base modules separate the 
      per-element-type groups from the element type declarations
      into separate files. Domains put both in one file.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:template match="/" mode="groupFile moduleFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="groupFile" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Nothing to do -->
  </xsl:template>
  
  <xsl:template mode="moduleFile" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Nothing to do -->    
  </xsl:template>
  
  <xsl:template mode="groupFile" match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> + [INFO] === <xsl:value-of select="rngfunc:getModuleShortName(.)"/>: Generating Grp.xsd file...</xsl:message>
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='xsdGrp'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" >
      <xsl:namespace name="ditaarch">http://dita.oasis-open.org/architecture/2005/</xsl:namespace>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:schema>
  </xsl:template>
  
  <xsl:template mode="moduleFile" match="rng:grammar">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:message> + [INFO] === <xsl:value-of select="rngfunc:getModuleShortName(.)"/>: Generating Mod.xsd file...</xsl:message>
    
    <xsl:apply-templates 
      select="(dita:moduleDesc/dita:headerComment[@fileType='xsdMod'], dita:moduleDesc/dita:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      <xsl:namespace name="ditaarch">http://dita.oasis-open.org/architecture/2005/</xsl:namespace>

      <xsl:if test="rngfunc:getModuleType(.) = ('map', 'topic')">
        <xsl:text>&#x0a;</xsl:text>
        <xsl:comment> ==================== Import Section ======================= </xsl:comment>
        <xsl:text>&#x0a;</xsl:text>
        <xs:import namespace="http://dita.oasis-open.org/architecture/2005/">
          <xsl:choose>
            <xsl:when test="$doUseURNsInShell">
              <xsl:attribute name="schemaLocation" select="concat('urn:oasis:names:tc:dita:xsd:ditaarch.xsd:',$ditaVersion)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="schemaLocation" select="'../../base/xsd/ditaarch.xsd'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xs:import>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:text>&#x0a;</xsl:text>
      </xsl:if>
      
      <xsl:apply-templates select=".//rng:externalRef" mode="constructExternalRefImports"/>
      
      <xsl:if test="rngfunc:getModuleShortName(.) = 'commonElements' or .//rng:attribute[starts-with(@name, 'xml:')]">
        <xsl:text>&#x0a;</xsl:text>
        <xsl:choose>
          <xsl:when test=".//rng:attribute[starts-with(@name, 'xml:')]">
            <xsl:comment> ==================== Import Section ======================= </xsl:comment>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment>  Import the XML Schema that contains the definitions for xml:lang and xml:space attributes </xsl:comment>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#x0a;</xsl:text>
        <xs:import namespace="http://www.w3.org/XML/1998/namespace">
          <xsl:choose>
            <xsl:when test="$doUseURNsInShell">
              <xsl:attribute name="schemaLocation" select="concat('urn:oasis:names:tc:dita:xsd:xml.xsd:',$ditaVersion)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="schemaLocation" select="'../../base/xsd/xml.xsd'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xs:import>
      </xsl:if>
            
      <xs:annotation>
        <xs:appinfo>
          <dita:domainsModule xmlns:dita="http://dita.oasis-open.org/architecture/2005/"
            ><xsl:value-of select="rngfunc:getDomainsContribution(.)"/></dita:domainsModule>
        </xs:appinfo>
      </xs:annotation>
      <xsl:text>&#x0a;</xsl:text>
      
      <xsl:choose>
        <xsl:when test="rngfunc:getModuleShortName(.) = ('commonElements', 'tblDecl', 'metaDecl') or rngfunc:getModuleType(.) = ('topic', 'map')">
          <!-- No groups in the Mod.xsd file -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="groupFile" select="rng:define/rng:element">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:variable name="domainPrefix" 
        as="xs:string"
        select="concat(rngfunc:getModuleShortName(.), '-')"
      /> 
      
      <!-- CommonElementsMod has some additional declarations specific to the XSD that
           have no direct correlate in the RNG declarations.
        -->
      
      <xsl:if test="rngfunc:getModuleShortName(.) = 'commonElements'">
        	<xs:attribute name="class" type="xs:string">
        		<xs:annotation>
        			<xs:documentation>
                        The class attribute supports specialization. Its predefined values help 
                        the output transforms work correctly with ranges of related content. 
                    </xs:documentation>
        		</xs:annotation>
        	</xs:attribute>

      </xsl:if>

      <!-- The handleDefinitionsForMod mode handles all definitions except the 
           element-specific .content and .attributes definitions, which are
           handled through the rng:element processing.
           
           This mode should produce all other groups and attribute groups
           that should result from rng:define elements.
        -->
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] Applying templates to the following defines:
<xsl:sequence select="for $def in (rng:define | rng:include) except 
                    (rng:define[.//rng:attribute[@name='class']]) return string($def/@name)"></xsl:sequence>      
        </xsl:message>
      </xsl:if>
           
      <xsl:choose>
        <xsl:when test="rngfunc:isConstraintModule(root(.))">
          <!-- For constraint modules, we need to process any includes before any defines
               because XSD requires that xs:redefines precede any xs:group declarations.
            -->
          <xsl:apply-templates mode="handleDefinitionsForMod" 
            select="(rng:include, rng:define) except 
            (rng:define[.//rng:attribute[@name='class']])"
            >
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="domainPrefix" select="$domainPrefix" tunnel="yes" as="xs:string" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="handleDefinitionsForMod" 
            select="(rng:define | rng:include) except 
            (rng:define[.//rng:attribute[@name='class']])"
            >
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
            <xsl:with-param name="domainPrefix" select="$domainPrefix" tunnel="yes" as="xs:string" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xs:schema>
  </xsl:template>
  
  <xsl:template match="rng:*" priority="-1" mode="moduleFile">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] moduleFile: Unhandled RNG element <xsl:sequence select="concat(name(..), '/', name(.))" /></xsl:message>
  </xsl:template>
  
  
  <!-- ====================
       Mode groupFile
       
       The groups are equivalent to the element-type-name 
       entities in the DTDs. There is one per unique element
       type.
       
   <xs:group name="tt">
      <xs:sequence>
         <xs:choice>
            <xs:element ref="tt"/>
         </xs:choice>
      </xs:sequence>
   </xs:group>

       ==================== -->
  <xsl:template mode="groupFile" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="rng:element" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template mode="groupFile" match="rng:define[ends-with(@name, '-attribute-extensions')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] groupFile: Define that ends with -attribute-extensions.</xsl:message>
    </xsl:if>
    <xsl:if test="rngfunc:getModuleShortName(root(.)/*) = 'commonElements'">
      <xs:attributeGroup name="{@name}">
        <xsl:apply-templates mode="#current"/>
      </xs:attributeGroup>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="groupFile" match="rng:define/rng:empty">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Nothing do do. For XSD an empty thing is just empty. -->
  </xsl:template>  
  
  <xsl:template match="rng:define[string(@name) = ('props-attribute-extensions', 'base-attribute-extensions')]"  
    mode="handleDefinitionsForMod" priority="30">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Suppressed in Mod.xsd file. Goes in the Grp.xsd file -->
  </xsl:template>
  
  
  <xsl:template mode="groupFile" match="rng:element">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:group name="{@name}">
        <xs:sequence>
           <xs:choice>
              <xs:element ref="{@name}"/>
           </xs:choice>
        </xs:sequence>
     </xs:group>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template mode="groupFile" match="a:* | dita:moduleDesc">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Ignore documentation -->
  </xsl:template>

  <xsl:template mode="groupFile" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> + [WARN] groupFile: Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
  </xsl:template>
  
  <!-- ============================
       Mode handleDefinitionsForMod
       ============================ -->

  <!-- Class attributes are handled in a separate mode -->
  <xsl:template match="rng:define[.//rng:attribute[@name='class']]" mode="handleDefinitionsForMod" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: Contains @class attribute declaration.</xsl:message>
    </xsl:if>
  </xsl:template>
  

  <xsl:template match="rng:define[@combine = 'choice']" mode="handleDefinitionsForMod" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: Domain integration pattern. Not output in the XSD.</xsl:message>
    </xsl:if>
      <!-- Domain integration pattern. Not output in the XSD. -->
  </xsl:template>


  <xsl:template match="rng:define[ends-with(@name, '.content') or ends-with(@name, '.attributes')]" 
    mode="handleDefinitionsForMod" priority="15">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: .content or .attributes, ignoring or not</xsl:message>
    </xsl:if>

    <xsl:if test="ends-with(@name, '.attributes')">
      <xsl:if test="count(tokenize(@name, '\.')) gt 2">
        <xsl:next-match/><!-- Handle cases like "dita.table.attributes" -->
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and key('definesByName',rng:ref/@name)/rng:element]" 
                mode="handleDefinitionsForMod" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: reference to element name in this module, will be in the group file</xsl:message>
    </xsl:if>
      <!-- reference to element name in this module, will be in the group file -->
  </xsl:template>
  
  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and 
                                  not(key('definesByName',rng:ref/@name)) and 
                                  ends-with(rng:ref/@name, '.element')]" 
                mode="handleDefinitionsForMod" priority="20">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: reference to element name in another module, will be in group file</xsl:message>
    </xsl:if>
      <!-- reference to element name in another module, will be in group file -->
  </xsl:template>
  
  <xsl:template match="rng:define[ends-with(@name, '-info-types')]" 
    mode="handleDefinitionsForMod" priority="40">
    <!-- FIXME: This may need to be more dynamic, not sure. -->
    <!-- NOTE: This pattern differs from the RNG/DTD pattern because
               of restrictions imposed by xs:redefine.
      -->
    <xs:group name="{rngfunc:getModuleShortName(/*)}-info-types">
      <xs:choice>
        <xs:group ref="{rngfunc:getModuleShortName(/*)}"/>
        <xs:group ref="info-types" />
      </xs:choice>
    </xs:group>
    
  </xsl:template>

  <xsl:template match="rng:define[starts-with(@name, concat(rngfunc:getModuleShortName(root(.)/*), '-'))]" 
                mode="handleDefinitionsForMod" priority="30">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Domain integration group. References to *.element groups need to become references
         to the elements themselves.
      -->
    <xs:group name="{@name}">
      <xs:choice>
        <xsl:apply-templates mode="refToTagname">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xs:choice>
    </xs:group>
    <xsl:text>&#x0a;</xsl:text>
  </xsl:template>  
  
  <xsl:template match="rng:define[ends-with(@name, '-attribute')]"  
    mode="handleDefinitionsForMod" priority="40">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Attribute specialization definition group -->
    <xsl:apply-templates select="." mode="generate-group-decl-from-define"/>
  </xsl:template>  
  
  <xsl:template mode="refToTagname" match="text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
  </xsl:template>  
  
  <xsl:template mode="refToTagname" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="refToTagname" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="target" select="@name" as="xs:string"/>
    <xsl:variable name="elementDecls" as="element()*"
      select="key('definesByName', $target)"
    />
    <xsl:variable name="elementDecl"
      select="($elementDecls/rng:element)[1]"
    />
    <xsl:choose>
      <xsl:when test="$elementDecl">
         <xs:element ref="{$elementDecl/@name}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment> Failed to find element declaration for reference "<xsl:value-of select="@name"/>" </xsl:comment>
        <xsl:message> - [WARN] refToTagname: Failed to find element declaration for reference "<xsl:value-of select="@name"/>"</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="rng:define" mode="handleDefinitionsForMod" priority="8">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Main template for generating group declarations from defines. 
    
         Note that the .content and .attributes handling is driven from within the rng:element
    -->
    <xsl:param name="domainPrefix" tunnel="yes" as="xs:string" />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/></xsl:message>
    </xsl:if>

    <xsl:apply-templates mode="generate-group-decl-from-define" select=".">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="handleDefinitionsForMod" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="rngfunc:isConstraintModule(root(.))">
<!--      <xsl:variable name="doDebug" as="xs:boolean" select="true()"/>-->
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] handleDefinitionsForMod: rng:include: Module is a constraint, applying templates in generateConstraintDeclarations mode...</xsl:message>
      </xsl:if>
      <xsl:apply-templates mode="generateConstraintDeclarations" select=".">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
      <xsl:if test="$doDebug">
        <xsl:message> + [DEBUG] handleDefinitionsForMod: rng:include: Done generating constraint declarations.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="handleDefinitionsForMod" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] handleDefinitionsForMod: Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
  </xsl:template>
  
  <!-- ====================================
       Mode generateConstraintDeclarations
       ==================================== -->

  <xsl:template mode="generateConstraintDeclarations" match="rng:include">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="schemaOutputDir" as="xs:string" tunnel="yes"/>
    <!-- Only constraint modules should have includes. These become redefines
         in the generated XSD.
      -->
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateConstraintDeclarations: Include of module <xsl:value-of select="@href"/></xsl:message>
    </xsl:if>
    
    <xsl:variable name="referencingRngModuleUrl" as="xs:string"
      select="if (root(.)/*/@origURI) then root(.)/*/@origURI else base-uri(.)"
    />
    <xsl:variable name="targetUrl" as="xs:string"
      select="relpath:newFile(relpath:getParent($referencingRngModuleUrl), string(@href))"
    />
    
    <xsl:variable name="referencedRngModule" as="document-node()"
      select="document($targetUrl)"
    />
    <!-- Special case for the taskbody and learning aggregation constraints -->
    <xsl:variable name="moduleType" as="xs:string"
      select="if (rng:define[@name = ('taskbody.content', 'mapgroup-d-topicref', 'topicref')]) 
                 then 'Mod' 
                 else 'Grp'"
    />
    <xsl:variable name="moduleUri" as="xs:string"
      select="local:getModuleUri(
      $moduleType,
      $referencedRngModule, 
      $schemaOutputDir, 
      $referencingRngModuleUrl)"
    />      
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateConstraintDeclarations: moduleUri="<xsl:value-of select="$moduleUri"/>"</xsl:message>
    </xsl:if>
    <xs:redefine schemaLocation="{$moduleUri}">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
      </xsl:apply-templates>
    </xs:redefine>      
    
  </xsl:template>
  
  <xsl:template mode="generateConstraintDeclarations" match="rng:define[ends-with(@name, '-info-types')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Handle info-types group declaration -->    
  </xsl:template>
  
  <xsl:template mode="generateConstraintDeclarations" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:choose>
      <xsl:when test="@name = 'taskbody.content'">
        <xsl:call-template name="generate-taskbody-constraint">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="generate-group-decl-from-define">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- ====================================
       Mode generate-group-decl-from-define
       ==================================== -->

  <xsl:template mode="generate-group-decl-from-define" match="rng:define[@name = 'arch-atts']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- arch-atts declaration is hard-coded -->
  </xsl:template>

  <xsl:template mode="generate-group-decl-from-define" match="rng:define[rng:element]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="rng:element" mode="handleDefinitionsForMod">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template mode="generate-group-decl-from-define" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- FIXME: The following is a hack that depends on a consistent naming convention
         for attribute sets.
         
         The more complete solution I think requires producing a single-document resolved
         grammar (e.g., RNG simplification) and then examining the define in that 
         grammar to see if it has any attribute declarations.
      -->
    <xsl:variable name="isAttSet" as="xs:boolean"
      select="matches(@name, '-atts|attribute|\.att') or .//rng:attribute"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-group-decl-from-define (rng2ditaxsdmod.xsl): rng:define, name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="@name = 'bodyatt'">
        <!-- Suppress in XSDs. Was not included in original XSDs -->
      </xsl:when>
      <xsl:when test="$isAttSet">
        <xs:attributeGroup name="{@name}">
          <xsl:apply-templates mode="generateXsdAttributeDecls">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xs:attributeGroup>
      </xsl:when>
      <xsl:otherwise>
        <xs:group name="{@name}">
          <xs:sequence>
            <xsl:apply-templates mode="generateXsdContentModel">
              <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
              <xsl:with-param name="isAttSet" as="xs:boolean" select="$isAttSet" tunnel="yes"/>      
            </xsl:apply-templates>
          </xs:sequence>
        </xs:group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="a:documentation">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:annotation>
      <xs:documentation>
        <xsl:apply-templates select="." mode="documentation">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xs:documentation>
    </xs:annotation>
  </xsl:template>
  
  <xsl:template mode="handleDefinitionsForMod" match="rng:element">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="normalizedGrammar" tunnel="yes" as="document-node()"/>
    <xsl:variable name="normalizedElement" as="element()"
      select="key('elementsByName', string(@name), $normalizedGrammar)"
    />
    <xs:element name="{@name}">
      <xs:annotation>
        <xs:documentation>
          <xsl:apply-templates select="a:documentation" mode="documentation">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xs:documentation>
      </xs:annotation>
      <xs:complexType>
        <xs:complexContent>
          <xs:extension base="{@name}.class">
            <xs:attribute ref="class" default="{local:getElementClassValue($normalizedElement, $doDebug)}"/>
          </xs:extension>
        </xs:complexContent>
      </xs:complexType>
    </xs:element>
    <xs:complexType name="{@name}.class">
      <xsl:variable name="isMixed" as="xs:boolean"
        select="rngfunc:isMixedContent($normalizedElement)"/>

      <xsl:if test="$doDebug and $normalizedElement/@name = 'author' and not($isMixed)">
        <xsl:message> + [DEBUG] rng:element: <xsl:value-of select="@name"/>: rngfunc:isMixedContent($normalizedElement)=<xsl:value-of select="$isMixed"/></xsl:message>
        <xsl:message> + [DEBUG]   rng:element: <xsl:value-of select="@name"/>: $normalizedElement=
          <xsl:sequence select="$normalizedElement"/>
        </xsl:message>
      </xsl:if>
      <xsl:if test="$isMixed">
        <xsl:attribute name="mixed" select="'true'"/>
      </xsl:if>
      <xs:sequence>
        <xs:group ref="{@name}.content"/>
      </xs:sequence>
      <xs:attributeGroup ref="{@name}.attributes"/>
    </xs:complexType>
    
    <xsl:choose>
      <xsl:when test="string(ancestor::rng:define[1]/@name) = 'taskbody.element'">
        <xsl:call-template name="generate-taskbody-content">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xs:group name="{@name}.content">
          <xsl:variable name="contentPatternName" as="xs:string"
            select="concat(@name, '.content')"
          />
          <xsl:apply-templates 
            select="rng:ref[@name = $contentPatternName]" 
            mode="generateXsdContentModel">
            <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          </xsl:apply-templates>
        </xs:group>
      </xsl:otherwise>
    </xsl:choose>
    
    <xs:attributeGroup name="{@name}.attributes">
      <xsl:variable name="attributesPatternName" as="xs:string"
        select="concat(@name, '.attlist')"
      />
      <!-- We only want those attributes defined in the tagname.attributes
           pattern for the element type. The global-atts group is
           an invariant reference and the @class attribute is handled
           separately.
           
           Process the tagname.attlist pattern, which then references 
           the tagname.attributes pattern and other patterns used
           for specific element types (e.g., topic types).
        -->
      <xsl:apply-templates 
        select="../../rng:define[@name = $attributesPatternName][not(.//rng:attribute[@name = 'class'])]" 
        mode="doElementTypeAttlistGeneration">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        <xsl:with-param name="tagname" select="@name" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>      
      <xs:attributeGroup ref="global-atts"/>
    </xs:attributeGroup>
  </xsl:template>
  
  <xsl:template match="*" mode="handleDefinitionsForMod" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] Mode handleDefinitionsForMod: Unhandled element <xsl:value-of select="name(..), '/', name(.)"/></xsl:message>
  </xsl:template>

  <!-- ============================
       Mode generateXsdContentModel
       ============================ -->
  
  <xsl:template mode="generateXsdContentModel" match="rng:element/rng:ref" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateXsdContentModel: rng:ref name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="contentPattern" select="key('definesByName', string(@name))"
      as="element(rng:define)*"
    />
    <xsl:apply-templates mode="#current" select="$contentPattern">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="a:*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Ignore -->
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:define[rng:data]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Nothing to output in content model mode. -->
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:sequence>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:sequence>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="rng:group">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:sequence>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:sequence>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="rng:zeroOrMore">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="rng:oneOrMore">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" match="rng:optional">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:choice">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:choice>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:choice>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:zeroOrMore/rng:choice" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:choice minOccurs="0" maxOccurs="unbounded">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:choice>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:oneOrMore[count(* except (a:documentation)) gt 1]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xs:sequence minOccurs="1" maxOccurs="unbounded">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:sequence>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:oneOrMore/rng:choice" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xs:choice minOccurs="1" maxOccurs="unbounded">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:choice>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:oneOrMore/rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:group ref="{@name}" minOccurs="1" maxOccurs="unbounded"/>
  </xsl:template>  
  
  <xsl:template mode="generateXsdContentModel" match="rng:optional/rng:choice" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:choice minOccurs="0">
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:choice>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:group ref="{@name}"/>
  </xsl:template>
  <xsl:template mode="generateXsdContentModel" match="rng:ref[@name = 'any']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:sequence minOccurs="0" maxOccurs="unbounded">
				<xs:any processContents="skip"/>
			</xs:sequence>
  </xsl:template>  
  
  <xsl:template mode="generateXsdContentModel" match="rng:optional/rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:group ref="{@name}" minOccurs="0"/>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel" match="rng:zeroOrMore/rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:group ref="{@name}" minOccurs="0" maxOccurs="unbounded"/>
  </xsl:template>

  <xsl:template match="rng:externalRef" mode="constructExternalRefImports">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] constructExternalRefImports: handling rng:externalRef</xsl:message>
    </xsl:if>
    <xsl:variable name="targetUri" as="xs:string?"
      select="@dita:xsdURI"
    />
    <xsl:choose>
      <xsl:when test="not($targetUri)">
        <xsl:message> - [WARN] No @dita:xsdURI attribute for rng:externalRef with href "<xsl:value-of select="@href"/>".</xsl:message>
        <xsl:message> - [WARN]    Cannot construct import for the foreign vocabulary.</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="targetNamespace" as="xs:string?"
          select="@dita:xsdTargetNamespace"
        />
        <xsl:choose>
          <xsl:when test="not($targetNamespace)">
          <xsl:message> - [WARN] No @dita:xsdTargetNamespace for rng:externalRef with href "<xsl:value-of select="@href"/>".</xsl:message>
          <xsl:message> - [WARN]    Foreign vocabularies must be in a namespace.</xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <xs:import schemaLocation="{$targetUri}" namespace="{$targetNamespace}"/>
          </xsl:otherwise>
        </xsl:choose>        
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rng:externalRef" mode="generateXsdContentModel">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="occurrence" as="xs:string?" select="()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateXsdContentModel: rng:externalRef, href="<xsl:value-of select="@href"/>"</xsl:message>
    </xsl:if>
    
    <!-- External refs are to grammars that are not merged, so we need to get
         the list of allowed start elements and emit them here as
         options in the current group.
      -->
    
    <xsl:variable name="elementTypeNames" as="xs:string*"
      select="rngfunc:getStartElementsForExternalRef(., $doDebug)"
    />
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateXsdContentModel: externalRef - elementTypeNames != '' ="<xsl:value-of select="$elementTypeNames != ''"/>"</xsl:message>
    </xsl:if>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generateXsdContentModel: externalRef - elementTypeNames="<xsl:value-of select="$elementTypeNames"/>"</xsl:message>
    </xsl:if>

    <xsl:variable name="namespacePrefix" as="xs:string?"
      select="if (@dita:namespacePrefix) then @dita:namespacePrefix else 'ns1'"
    />
    <xsl:if test="not(@dita:namespacePrefix)">
      <xsl:message> - [WARN] No @dita:namespacePrefix for rng:externalRef with href "<xsl:value-of select="@href"/>".</xsl:message>
      <xsl:message> - [WARN]    Foreign vocabularies must be in a namespace.</xsl:message>
    </xsl:if>

    <xsl:variable name="targetNamespace" as="xs:string?"
      select="@dita:xsdTargetNamespace"
    />
    <xsl:if test="not($targetNamespace)">
      <xsl:message> - [WARN] No @dita:xsdTargetNamespace for rng:externalRef with href "<xsl:value-of select="@href"/>".</xsl:message>
      <xsl:message> - [WARN]    Foreign vocabularies must be in a namespace.</xsl:message>
    </xsl:if>
    <xsl:for-each select="$elementTypeNames">
      <xs:element ref="{$namespacePrefix}:{.}" >
        <xsl:namespace name="{$namespacePrefix}"><xsl:value-of select="$targetNamespace"/></xsl:namespace>
      </xs:element>
    </xsl:for-each>
    
    <xsl:if test="not(position() = last())">
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>
  

  <xsl:template mode="generateXsdContentModel" match="rng:text">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Becomes mixed="true" -->
  </xsl:template>

  <xsl:template mode="generateXsdContentModel" match="rng:empty">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Empty sequence in XSD -->
  </xsl:template>

  
  <xsl:template mode="generateXsdContentModel" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] generateXsdContentModel: Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
  </xsl:template>
  
  <!-- ==============================
       Mode generateXsdAttributeDecls
       ============================== -->
 
 <xsl:template mode="doElementTypeAttlistGeneration" match="rng:define">
   <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
   <!-- This mode handles the .attlist pattern used for each unique 
        element type.
     -->
   <xsl:apply-templates mode="generateXsdAttributeDecls">
     <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
   </xsl:apply-templates>
 </xsl:template>
 
  <xsl:template mode="generateXsdAttributeDecls" match="rng:empty">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Do nothing. Result should be an empty xs:attributeGroup element -->
  </xsl:template>

  <xsl:template mode="generateXsdAttributeDecls" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="@name = 'bodyatt'">
      <xsl:message> **** [DEBUG] rng:ref name="bodyatt"</xsl:message>
    </xsl:if>
    <xs:attributeGroup ref="{@name}"/>
  </xsl:template>

  <xsl:template match="rng:define[count(rng:*)=1 and rng:ref and key('attlistIndex',@name)]" 
                mode="handleDefinitionsForMod" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] handleDefinitionsForMod: Main template: Handling define: <xsl:value-of select="@name"/>: .attlist pointing to .attributes, ignore</xsl:message>
    </xsl:if>
      <!-- .attlist pointing to .attributes, ignore -->
  </xsl:template>

  <xsl:template mode="generateXsdAttributeDecls" match="rng:ref[ends-with(@name, '.attributes')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="tagname" as="xs:string" tunnel="yes" select="'#unset'"/>
    <xsl:choose>
      <xsl:when test="@name = concat($tagname, '.attributes')">
        <xsl:variable name="targetDefine" as="element()*"
          select="key('definesByName', string(@name), root(.))"
        />
        <xsl:apply-templates select="$targetDefine/*" mode="#current">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$tagname = '#unset'">
        <!-- Not in context of a element type declaration, suppress -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="rng:ref[@name='arch-atts']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:attribute ref="ditaarch:DITAArchVersion"/>
  </xsl:template>

  <xsl:template mode="generateXsdAttributeDecls" match="rng:attribute[matches(@name,'^xml:.+')]"
    priority="100">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:attribute ref="{@name}"/>      
  </xsl:template>

  <xsl:template mode="generateXsdAttributeDecls" match="rng:define/rng:attribute ">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- NOTE: attributes not declared within rng:optional are required -->
    <xs:attribute name="{@name}" use="required">
      <xsl:if test="not(rng:choice)">
        <xsl:attribute name="type" select="'xs:string'"/>
      </xsl:if>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:attribute>
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="rng:optional/rng:attribute" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] rng:optional/rng:attribute: name="<xsl:value-of select="@name"/>"</xsl:message>
    </xsl:if>
    <xs:attribute name="{@name}">
      <xsl:if test="not(rng:choice | rng:data)">
        <xsl:attribute name="type" select="'xs:string'"/>
      </xsl:if>
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:attribute>
  </xsl:template>
  
  <xsl:template match="rng:attribute/rng:ref" mode="generateXsdAttributeDecls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- The reference should be to a datatype defintion -->
    <xsl:variable name="data" as="node()*"
      select="key('definesByName',string(@name))"
    />
    <xsl:if test="not($data)">
      <xsl:message> - [WARN] rng:attribute/rng:ref: <xsl:value-of select="name(..)"/> - Failed to resolve reference to define "<xsl:value-of select="@name"/>" </xsl:message>
    </xsl:if>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] rng:attribute/rng:ref: $data=<xsl:sequence select="$data"/></xsl:message>
    </xsl:if>
    <xsl:apply-templates select="$data" mode="generateXsdAttributeDecls">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="generateXsdContentModel generateXsdAttributeDecls" 
                match="rng:define[rng:data]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- We don't define anything for <rng:data> because in DITA through 1.3 we 
         are limited to the DTD-level type definitions, so no point in trying
         to generate simple or complex types for attribute values.
         
         Enumerated values are always declared directly on each attribute since
         each element type may use a different set of values for the same
         attribute name.
      -->
  </xsl:template>
 
  
  <xsl:template mode="generateXsdAttributeDecls" match="rng:data">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:variable name="rngType" select="@type" as="xs:string"/>
    <!-- NOTE: DITA base vocabulary only uses ID, NMTOKEN, and CDATA
         types on attributes. IDREF is never used.
      -->
    <xsl:attribute name="type"
      select="if ($rngType = 'ID') then 'xs:ID'
       else if ($rngType = 'NMTOKEN')
         then 'xs:NMTOKEN'
         else 'xs:string'
         "
    />
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="*" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] generateXsdAttributeDecls: Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/></xsl:message>
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="rng:choice">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:simpleType>
      <xs:restriction base="xs:string">
        <!-- Have to exclude annotation elements because you can't
             have annotation directly within xs:restriction 
          -->
        <xsl:apply-templates mode="#current" select="rng:value">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xs:restriction>
    </xs:simpleType>
  </xsl:template>
  
  <xsl:template mode="generateXsdAttributeDecls" match="rng:value">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xs:enumeration value="{normalize-space(.)}">
      <xsl:apply-templates select="following-sibling::*[1][self::a:documentation]" mode="#current">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xs:enumeration>    
  </xsl:template>
    

  
  <xsl:template match="a:*" mode="generateXsdAttributeDecls">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Ignore annotations -->
  </xsl:template>
  
  
  <!-- ==============================
       Mode documentation
       ============================== -->
  
  <xsl:template match="a:documentation" mode="documentation">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template  mode="documentation" match="text()">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:template match="a:documentation//*" mode="documentation" priority="-1">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARN] Unhandled element <xsl:value-of select="concat(name(..), '/', name(.))"/> within a:documentation element.</xsl:message>
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!-- ====================
       Mode header-comment
       ==================== -->

  <xsl:template match="dita:moduleDesc" mode="header-comment">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:apply-templates select="dita:headerComment" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="dita:headerComment" mode="header-comment">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- Note that the header comment is a single string with
         space preserved.
      -->
    <xsl:choose>
      <xsl:when test="$headerCommentStyle = 'comment-per-line'">
        <xsl:analyze-string select="." regex="^.+$" flags="m">
          <xsl:matching-substring>
            <xsl:comment><xsl:value-of select="str:pad(., 61)"/></xsl:comment>
            <xsl:text>&#x0a;</xsl:text>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:if test="normalize-space(.) != ''">
              <xsl:comment><xsl:value-of 
                select="str:pad(., 61)"/></xsl:comment>
              <xsl:text>&#x0a;</xsl:text>
            </xsl:if>
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment><xsl:value-of select="string(.)"/></xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="ensureXmlXsd">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="xsdOutputDir" tunnel="yes" as="xs:string"/>
    <!-- Ensure that there is a ditaarch.xsd file in the output base/xsd directory -->
    <xsl:variable name="xmlModUri" 
      select="relpath:newFile(relpath:newFile(relpath:newFile($xsdOutputDir, 'base'), 'xsd'), 'xml.xsd')"
      as="xs:string"
    />
    <xsl:variable name="xsdMod" as="document-node()"
      select="document('static-schemas/xml.xsd')"
    /> 
    <xsl:result-document href="{$xmlModUri}">
      <xsl:sequence select="$xsdMod/node()"/>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template name="ensureDitaArchXsd">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="xsdOutputDir" tunnel="yes" as="xs:string"/>
    <!-- Ensure that there is a ditaarch.xsd file in the output base/xsd directory -->
    <xsl:variable name="ditaarchModUri" 
      select="relpath:newFile(relpath:newFile(relpath:newFile($xsdOutputDir, 'base'), 'xsd'), 'ditaarch.xsd')"
      as="xs:string"
    />
      <!-- NOTE: We have to generate this rather than simply copying it 
           because we need to set the DITA version in the default value
           for the @ditaarch:DITAArchVersion attribute.
         -->
    <xsl:result-document href="{$ditaarchModUri}">
<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>                    HEADER                                     </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>  MODULE:    DITA DITA Architecture Attribute                  </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>  VERSION:   <xsl:value-of select="$ditaVersion"/>                                             </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>  DATE:      March 2014                                        </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>                                                               </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>

<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> SYSTEM:     Darwin Information Typing Architecture (DITA)     </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>                                                               </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> PURPOSE:    W3C XML Schema to describe DITA architecture      </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>             attribute                                         </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>                                                               </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> ORIGINAL CREATION DATE:                                       </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>             March 2001                                        </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>                                                               </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>             (C) Copyright OASIS-Open.org 2005, 2014           </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>             (C) Copyright IBM Corporation 2001, 2004.         </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment>             All Rights Reserved.                              </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xsl:comment> ============================================================= </xsl:comment><xsl:text>&#x0a;</xsl:text>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"  targetNamespace="http://dita.oasis-open.org/architecture/2005/" xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/">

  <xs:attribute name="DITAArchVersion" type="xs:string" default="{$ditaVersion}"/>

</xs:schema>
      </xsl:result-document>
  </xsl:template>
  
  <xsl:function name="local:getElementClassValue" as="xs:string">
    <xsl:param name="elementElem" as="element(rng:element)"/>
    <xsl:param name="doDebug" as="xs:boolean"/>
    <xsl:variable name="defineName" as="xs:string" 
      select="concat($elementElem/@name, '.attlist')"
    />
    <xsl:if test="$doDebug">
    </xsl:if>
    <xsl:variable name="classAtt" as="element(rng:attribute)?"
      select="($elementElem//rng:attribute[@name = 'class'])[1]"
    />
    <xsl:choose>
    <xsl:when test="not($classAtt)">
      <xsl:message> + [WARN] local:getElementClassValue(): Failed to find @class attribute declaration for element type "<xsl:value-of select="$elementElem/@name"/>"</xsl:message>
      <xsl:sequence select="'no class value'"></xsl:sequence>
    </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="classValue" as="xs:string" select="$classAtt/@a:defaultValue"/>
        <xsl:sequence select="$classValue"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
</xsl:stylesheet>