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
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  exclude-result-prefixes="xs xd rng rnga relpath str rngfunc local rng2ditadtd a"
  version="3.0">
  
  <!-- ===========================================================
       OASIS-specific overrides to the generic XSD generation 
       process.
       
       These overrides handle special cases that cannot be handled
       through generic algorithms.
       
       ============================================================ -->
  
  <!-- ==============================
       taskbody constraint overrides
       ============================== -->
  
  <xsl:template name="generate-taskbody-content"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <!-- The taskbody content for XSD has to be factored out into groups to
         then allow for constraint.
      -->
    
    <xs:group name="taskbody.content">
      <xs:sequence>
        <xs:group ref="taskPreStep"/>
        <xs:group ref="taskStep"/>
        <xs:group ref="taskPostStep"/>
      </xs:sequence>
    </xs:group>
    
    <xs:group name="taskPreStep">
      <xs:sequence>
        <xs:choice minOccurs="0" maxOccurs="unbounded">
          <xs:group ref="context" minOccurs="0"/>
          <xs:group ref="prereq"  minOccurs="0"/>
          <xs:group ref="section" minOccurs="0"/>
        </xs:choice>
      </xs:sequence>
    </xs:group>
    
    <xs:group name="taskPostStep">
      <xs:sequence>
        <xs:group ref="result"  minOccurs="0"/>
        <xsl:if test="$ditaVersion = '1.3'">
          <xs:group ref="tasktroubleshooting" minOccurs="0"/>
        </xsl:if>
        <xs:group ref="example"  minOccurs="0" maxOccurs="unbounded"/>
        <xs:group ref="postreq"  minOccurs="0" maxOccurs="unbounded"/>  
      </xs:sequence>
    </xs:group>
    
    <xs:group name="taskStep">
      <xs:sequence>
        <xs:choice minOccurs="0" maxOccurs="1">
          <xs:group ref="steps" />
          <xs:group ref="steps-unordered" />
          <xs:group ref="steps-informal" />
        </xs:choice>
      </xs:sequence>
    </xs:group>
    
  </xsl:template>
  
  <xsl:template name="generate-taskbody-constraint">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] generate-taskbody-constraint: taskbody.content override</xsl:message>
    </xsl:if>
    
    <!-- These groups are the content of the xs:redefine generated from the corresponding
         rng:include element.
      -->
    
      <xs:group name="taskPreStep" xmlns:xs="http://www.w3.org/2001/XMLSchema">  
        <xs:sequence>
          <xs:choice> 
            <xs:sequence>
              <xs:group ref="prereq"  minOccurs="0"/>
              <xs:group ref="context"  minOccurs="0"/>
            </xs:sequence>
          </xs:choice>
        </xs:sequence>
      </xs:group>
      
      <xs:group name="taskPostStep" xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:sequence>
          <xs:sequence>
            <xs:group ref="result"  minOccurs="0"/>
            <xsl:if test="$ditaVersion = '1.3'">
              <xs:group ref="tasktroubleshooting" minOccurs="0"/>
            </xsl:if>
            <xs:group ref="example"  minOccurs="0"/>
            <xs:group ref="postreq"  minOccurs="0"/>
          </xs:sequence>
        </xs:sequence>
      </xs:group>  
      
      <xs:group name="taskStep">
        <xs:sequence>
          <xs:choice minOccurs="0" maxOccurs="1">
            <xs:group ref="steps" />
            <xs:group ref="steps-unordered" />
          </xs:choice>
        </xs:sequence>
      </xs:group>
      
      <xs:group name="task-info-types">
        <xs:choice>
          <xs:group ref="task-info-types"/>
        </xs:choice>
      </xs:group>
    
  </xsl:template>
  
  <xsl:template mode="#all" match="rng:define[@name = 'bodyatt']" priority="10">
    <!-- Suppress. Not included in the 1.2 XSDs -->
<!--    <xsl:message> + [DEBUG] generate-group-decl-from-define: override for bodyatt </xsl:message>-->
  </xsl:template>
  
  <xsl:template mode="#all" match="rng:ref[@name = 'bodyatt']" priority="10">
    <!-- Suppress. Not included in the 1.2 XSDs -->
<!--    <xsl:message> + [DEBUG] generateXsdAttributeDecls: override for rng:ref, @name=bodyatt </xsl:message>-->
  </xsl:template>

  <xsl:template mode="generateXsdAttributeDecls" match="rng:*[@name = 'bodyatt']">
    <!-- Suppress. Not included in the 1.2 XSDs -->
    <xsl:message> + [DEBUG] generateXsdAttributeDecls: override for rng:*, @name=bodyatt </xsl:message>
  </xsl:template>
  
  <!-- ==================================
       Glossary and glossaryMod overrides
       ================================== -->
  
  <xsl:template match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']" mode="xsdFile" priority="100">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="xsdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    
    <!-- Generate an XSD shell for a map or topic type -->
    
    <xsl:message> + [INFO] === Generating XSD shell {$xsdFilename}...</xsl:message>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] xsdFile: rng:grammar: Override for glossary shell.</xsl:message>
    </xsl:if>
    
    <!-- Generate the header comment -->
    <xsl:apply-templates 
      select="(ditaarch:moduleDesc/ditaarch:headerComment[@fileType='xsdShell'], ditaarch:moduleDesc/ditaarch:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <!-- Generate the glossary redirection shell: -->

    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified"
      attributeFormDefault="unqualified" xmlns:ditaarch="http://dita.oasis-open.org/architecture/2005/">
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> NOTE: The glossary.xsd file was misnamed in DITA 1.1. For DITA 1.2+, it simply
    redirects to the correctly-named glossentry.xsd file.</xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
      
      <xs:include schemaLocation="urn:oasis:names:tc:dita:xsd:glossentry.xsd:{$ditaVersion}"/>  
      
    </xs:schema>

  </xsl:template>  
  
  <xsl:template mode="groupFile" match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:message> + [INFO] === {rngfunc:getModuleShortName(.)}: Generating Grp.xsd file...</xsl:message>
    <xsl:apply-templates 
      select="(ditaarch:moduleDesc/ditaarch:headerComment[@fileType='xsdGrp'], ditaarch:moduleDesc/ditaarch:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      
      <xsl:text>&#x0a;</xsl:text>
<xsl:comment> NOTE: The glossaryGrp.xsd file was misnamed in DITA 1.1. For DITA 1.2+, it simply
    redirects to the correctly-named glossentryGrp.xsd file.
    </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
      <xs:include schemaLocation="urn:oasis:names:tc:dita:xsd:glossentryGrp.xsd:{$ditaVersion}"/>  
      
    </xs:schema>
  </xsl:template>
  
  <xsl:template mode="moduleFile" match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary']">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:message> + [INFO] === {rngfunc:getModuleShortName(.)}: Generating Mod.xsd file...</xsl:message>
    <xsl:apply-templates 
      select="(ditaarch:moduleDesc/ditaarch:headerComment[@fileType='xsdMod'], ditaarch:moduleDesc/ditaarch:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      
      <xsl:text>&#x0a;</xsl:text>
      <xsl:comment> NOTE: The glossaryMod.xsd file was misnamed in DITA 1.1. For DITA 1.2+, it simply
    redirects to the correctly-named glossentryMod.xsd file.
    </xsl:comment>
      <xsl:text>&#x0a;</xsl:text>
      <xs:include schemaLocation="urn:oasis:names:tc:dita:xsd:glossentryMod.xsd:{$ditaVersion}"/>  
      
    </xs:schema>
  </xsl:template>
  
  <!-- =====================================
       Overrides for includes that need
       to be redefines (e.g., topic modules
       that redefine the *-info-types group
       ===================================== -->
  

  <xsl:template mode="handleTopLevelIncludes" match="rng:include[.//rng:define[ends-with(@name, '-info-types')]//rng:empty]"
    priority="20">
    <!-- An include of a topic module that sets the *-info-types pattern to empty. -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"></xsl:param>
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
    
    
    <xsl:variable name="includedRNGModule" as="document-node()?"
      select="document(@href, root(.))"
    />
    <xsl:if test="rngfunc:getModuleType($includedRNGModule/*) = ('topic', 'map')">
      
      <xsl:variable name="includedModuleShortName" as="xs:string"
        select="rngfunc:getModuleShortName($includedRNGModule/*)"
      />
      <xsl:variable name="xsdUri" as="xs:string"
        select="local:constructModuleSchemaLocation($includedRNGModule/*, 'mod', $xsdDir, $rngShellUrl)"
      />
      <xs:redefine schemaLocation="{$xsdUri}">
        <xsl:apply-templates select="a:documentation" mode="handleDocumentation"/>
        <xs:group name="{$includedModuleShortName}-info-types">
          <xs:choice>
            <xs:group ref="info-types"/>
          </xs:choice>
        </xs:group>
      </xs:redefine>
    </xsl:if>
  </xsl:template>
  
  
  <xsl:template mode="handleTopLevelIncludes" match="rng:include[.//rng:define[@name = 'learningContent-info-types']]" 
    priority="20">
    <!-- An include of a topic module that sets the *-info-types pattern to empty. -->
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"></xsl:param>
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
    
    
    <xsl:variable name="includedRNGModule" as="document-node()?"
      select="document(@href, root(.))"
    />
    <xsl:variable name="includedModuleShortName" as="xs:string"
      select="rngfunc:getModuleShortName($includedRNGModule/*)"
    />
    <xsl:variable name="xsdUri" as="xs:string"
      select="local:constructModuleSchemaLocation($includedRNGModule/*, 'mod', $xsdDir, $rngShellUrl)"
    />
    <xs:redefine schemaLocation="{$xsdUri}">
      <xsl:apply-templates select="a:documentation" mode="handleDocumentation"/>
      <xs:group name="learningContent-info-types">
        <xs:choice>
          <xs:group ref="info-types"/>
        </xs:choice>
      </xs:group>
      
      <xs:group name="learningContent.content">
        <xs:sequence>
          <xs:group ref="learningContent.content"/>
          <xs:choice minOccurs="0" maxOccurs="unbounded">
            <xs:element ref="concept"/>
            <xs:element ref="reference"/>
            <xs:element ref="task"/>
            <xs:element ref="topic"/>
          </xs:choice>
          <xs:sequence>
            <xs:element ref="learningAssessment" minOccurs="0"/>
            <xs:element ref="learningSummary" minOccurs="0"/>
          </xs:sequence>
        </xs:sequence>
      </xs:group>
    </xs:redefine>
  </xsl:template>
  
  
  <xsl:template mode="handleTopLevelIncludes" 
    match="rng:include[contains(@href, 'learningAggregationsTopicrefConstraintMod')]">
    <xsl:choose>
      <xsl:when test="$doUseURNsInShell">
        <xs:include schemaLocation="urn:oasis:names:tc:dita:xsd:mapGroupMod.xsd:1.3"/>
      </xsl:when>
      <xsl:otherwise>
        <xs:include schemaLocation="../../base/xsd/mapGroupMod.xsd"/>        
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  
  <!-- ============================
       Overrides for -info-types 
       ============================ -->
  
  <xsl:template match="
    rng:define[ends-with(@name, 'learningAssessment-info-types')] |
    rng:define[ends-with(@name, 'learningContent-info-types')] |
    rng:define[ends-with(@name, 'learningPlan-info-types')] |
    rng:define[ends-with(@name, 'learningSummary-info-types')] |
    rng:define[ends-with(@name, 'glossentry-info-types')] |
    rng:define[ends-with(@name, 'glossentry-info-types')] |
    rng:define[ends-with(@name, 'learningContentlearningOverview')]" 
    mode="handleDefinitionsForMod" priority="50">
    <xs:group name="{rngfunc:getModuleShortName(/*)}-info-types">
      <xs:sequence>
        <xs:choice>
          <xs:group ref="no-topic-nesting"/>
          <xs:group ref="info-types"/>
        </xs:choice>
      </xs:sequence>
    </xs:group>
    
  </xsl:template>

  <xsl:template match="rng:define[ends-with(@name, 'glossgroup-info-types')]" 
    mode="handleDefinitionsForMod" priority="50">
    <xs:group name="glossgroup-info-types">
      <xs:choice>
        <xs:group ref="glossgroup" />
        <xs:group ref="glossentry" />
        <xs:group ref="info-types"/>
      </xs:choice>
    </xs:group>    
  </xsl:template>  

  <!-- ============================
       Generate DITAVAL XSD
       ============================ -->
  
  <xsl:template match="rng:grammar[rngfunc:getModuleShortName(.) = 'ditaval']" mode="xsdFile" priority="100">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="xsdFilename" tunnel="yes" as="xs:string" />
    <xsl:param name="xsdDir" tunnel="yes" as="xs:string" />
    
    <!-- Generate an XSD shell for a map or topic type -->
    
    <xsl:message> + [INFO] === Generating XSD shell {$xsdFilename}...</xsl:message>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] xsdFile: rng:grammar: Special case for ditaval XSD.</xsl:message>
    </xsl:if>
    
    <!-- Generate the header comment -->
    <xsl:apply-templates 
      select="(ditaarch:moduleDesc/ditaarch:headerComment[@fileType='xsdShell'], ditaarch:moduleDesc/ditaarch:headerComment[1])[1]" 
      mode="header-comment"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <!-- While it would be possible to generate the XSD from the DITAVAL grammar, not bothering
         in advance of DITA 1.3 completion. If anyone wants to implement it, please contribute.
      -->

    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
      
      <xs:element name="val" type="val.class"/>
      
      <xs:complexType name="val.class">
        <xs:sequence>
          <xs:group ref="val.content"/>
        </xs:sequence>
        <!--<xs:attributeGroup ref="val.attributes"/>-->
      </xs:complexType>
      
      <xs:group name="val.content">
        <xs:sequence>
          <xs:group ref="style-conflict" minOccurs="0"/>
          <xs:choice minOccurs="0" maxOccurs="unbounded">
            <xs:group ref="prop"/>
            <xs:group ref="revprop"/>
          </xs:choice>
        </xs:sequence>
      </xs:group>
      
      <xs:element name="style-conflict" type="style-conflict.class"/>
      
      <xs:group name="style-conflict">
        <xs:choice>
          <xs:element ref="style-conflict"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="style-conflict.class">
        <xs:attributeGroup ref="style-conflict.attributes"/>
      </xs:complexType>
      
      <xs:attributeGroup name="style-conflict.attributes">
        <xs:attribute name="foreground-conflict-color" type="xs:string"/>
        <xs:attribute name="background-conflict-color" type="xs:string"/>
      </xs:attributeGroup>
      
      <xs:element name="prop" type="prop.class"/>
      
      <xs:group name="prop">
        <xs:choice>
          <xs:element ref="prop"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="prop.class">
        <xs:sequence>
          <xs:group ref="prop.content"/>
        </xs:sequence>
        <xs:attributeGroup ref="prop.attributes"/>
      </xs:complexType>
      
      <xs:group name="prop.content">
        <xs:sequence>
          <xs:group ref="startflag" minOccurs="0"/>
          <xs:group ref="endflag" minOccurs="0"/>
        </xs:sequence>
      </xs:group>
      
      <xs:attributeGroup name="prop.attributes">
        <xs:attribute name="att" type="xs:string"/>
        <xs:attribute name="val" type="xs:string"/>
        <xs:attribute name="action" use="required">
          <xs:simpleType>
            <xs:restriction base="xs:string">
              <xs:enumeration value="include"/>
              <xs:enumeration value="exclude"/>
              <xs:enumeration value="passthrough"/>
              <xs:enumeration value="flag"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:attribute>
        <xs:attribute name="color" type="xs:string"/>
        <xs:attribute name="backcolor" type="xs:string"/>
        <xs:attribute name="style" type="style-atts.class"/>
      </xs:attributeGroup>
      
      <xs:element name="revprop" type="revprop.class"/>
      
      <xs:group name="revprop">
        <xs:choice>
          <xs:element ref="revprop"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="revprop.class">
        <xs:sequence>
          <xs:group ref="revprop.content"/>
        </xs:sequence>
        <xs:attributeGroup ref="revprop.attributes"/>
      </xs:complexType>
      
      <xs:group name="revprop.content">
        <xs:sequence>
          <xs:group ref="startflag" minOccurs="0"/>
          <xs:group ref="endflag" minOccurs="0"/>
        </xs:sequence>
      </xs:group>
      
      <xs:attributeGroup name="revprop.attributes">
        <xs:attribute name="val" type="xs:string"/>
        <xs:attribute name="action" use="required">
          <xs:simpleType>
            <xs:restriction base="xs:string">
              <xs:enumeration value="include"/>
              <xs:enumeration value="passthrough"/>
              <xs:enumeration value="flag"/>
            </xs:restriction>
          </xs:simpleType>
        </xs:attribute>
        <xs:attribute name="color" type="xs:string"/>
        <xs:attribute name="changebar" type="xs:string"/>
        <xs:attribute name="backcolor" type="xs:string"/>
        <xs:attribute name="style" type="style-atts.class"/>
      </xs:attributeGroup>
      
      <xs:element name="startflag" type="startflag.class"/>
      
      <xs:group name="startflag">
        <xs:choice>
          <xs:element ref="startflag"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="startflag.class">
        <xs:sequence>
          <xs:group ref="startflag.content"/>
        </xs:sequence>
        <xs:attributeGroup ref="startflag.attributes"/>
      </xs:complexType>
      
      <xs:group name="startflag.content">
        <xs:sequence>
          <xs:group ref="alt-text" minOccurs="0"/>
        </xs:sequence>
      </xs:group>
      
      <xs:attributeGroup name="startflag.attributes">
        <xs:attribute name="imageref" type="xs:string"/>
      </xs:attributeGroup>
      
      <xs:element name="endflag" type="endflag.class"/>
      
      <xs:group name="endflag">
        <xs:choice>
          <xs:element ref="endflag"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="endflag.class">
        <xs:sequence>
          <xs:group ref="endflag.content"/>
        </xs:sequence>
        <xs:attributeGroup ref="endflag.attributes"/>
      </xs:complexType>
      
      <xs:group name="endflag.content">
        <xs:sequence>
          <xs:group ref="alt-text" minOccurs="0"/>
        </xs:sequence>
      </xs:group>
      
      <xs:attributeGroup name="endflag.attributes">
        <xs:attribute name="imageref" type="xs:string"/>
      </xs:attributeGroup>
      
      <xs:element name="alt-text" type="alt-text.class"/>
      
      <xs:group name="alt-text">
        <xs:choice>
          <xs:element ref="alt-text"/>
        </xs:choice>
      </xs:group>
      
      <xs:complexType name="alt-text.class" mixed="true">  
      </xs:complexType>
      
      
      <xs:simpleType name="style-atts.class">
        <xsl:choose>
          <xsl:when test="$ditaVersion = '1.3'">
            <xs:restriction base="xs:NMTOKENS">
            </xs:restriction>            
          </xsl:when>
          <xsl:otherwise>            
            <xs:restriction base="xs:string">
              <xs:enumeration value="underline"/>
              <xs:enumeration value="double-underline"/>
              <xs:enumeration value="italics"/>
              <xs:enumeration value="overline"/>
              <xs:enumeration value="bold"/>
            </xs:restriction>
          </xsl:otherwise>
        </xsl:choose>
      </xs:simpleType>
      
    </xs:schema>
  </xsl:template>
  
  <!-- Overrides for learningGroupMap and learningObjectMap -->
  
  
  <xsl:template mode="generateRedefineElement" 
    match="rng:grammar[rngfunc:getModuleShortName(.) = 'map']" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="rngShellUrl" tunnel="yes" as="xs:string"/>
    <xsl:param name="moduleUri" as="xs:string"/>
    <xsl:param name="elementTypeNames" as="xs:string*"/>
    <xsl:param name="elementExtensionDefines" as="node()*"/>
    <xsl:param name="attributeExtensionDefines" as="node()*"/>
    
    <xsl:choose>
      <xsl:when test="contains($rngShellUrl, 'learningObjectMap') or contains($rngShellUrl, 'learningGroupMap')">
        <xsl:variable name="schemaLocation" as="xs:string"
          select="if ($doUseURNsInShell) 
          then 'urn:oasis:names:tc:dita:xsd:mapGrp.xsd:1.3'
                     else '../../base/xsd/mapGrp.xsd'"
        />
        <xs:redefine schemaLocation="{$schemaLocation}">
          <xs:group name="topicref">
            <xs:choice>
              <xs:group ref="topicref"/>
              <xs:element ref="keydef"/>
              <xs:element ref="mapref"/>
              <xs:element ref="topicgroup"/>
              <xs:group ref="ditavalref-d-topicref"/>
              <xs:group ref="learningmap-d-topicref"/>
            </xs:choice>
          </xs:group>
        </xs:redefine>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match>
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
          <xsl:with-param name="rngShellUrl" tunnel="yes" as="xs:string" select="$rngShellUrl"/>
          <xsl:with-param name="moduleUri" as="xs:string" select="$moduleUri"/>
          <xsl:with-param name="elementTypeNames" as="xs:string*" select="$elementTypeNames"/>
          <xsl:with-param name="elementExtensionDefines" as="node()*" select="$elementExtensionDefines"/>
          <xsl:with-param name="attributeExtensionDefines" as="node()*" select="$attributeExtensionDefines"/>
        </xsl:next-match>
      </xsl:otherwise>
    </xsl:choose>
    
    
  </xsl:template>
  
  <xsl:template mode="getIncludedModules" priority="100" 
    match="rng:grammar[rngfunc:getModuleShortName(.) = 'glossary'][rngfunc:getModuleType(.) = 'topicshell']" 
    >
    <!-- Don't process references in the glossary.rng module. -->
  </xsl:template>
  

  <!-- ===========================================
       topLevelIncludesExtensions
       =========================================== -->
  
  <xsl:template mode="topLevelIncludesExtensions" 
    match="rng:grammar[rngfunc:getModuleShortName(.) = ('learningGroupMap', 'learningObjectMap')]">
    <xsl:choose>
      <xsl:when test="$doUseURNsInShell">
        <xs:include schemaLocation="urn:oasis:names:tc:dita:xsd:mapMod.xsd:1.3"/>
      </xsl:when>
      <xsl:otherwise>
        <xs:include schemaLocation="../../base/xsd/mapMod.xsd"/>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="*" mode="topLevelIncludesExtensions" priority="-1">
    <!-- default, do nothing. -->
  </xsl:template>
  
</xsl:stylesheet>