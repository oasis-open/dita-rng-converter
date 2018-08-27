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
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"  
  exclude-result-prefixes="xs xd rng rnga relpath a str ditaarch dita rngfunc local rng2ditadtd map"
  expand-text="yes"
  version="3.0"  
  >
  <!-- ====================================================
       Mode "generate-referenced-parameter-entities"
       
       For constraint modules, generate copies of all referenced
       parameter entities used within content models or attribute
       lists defined in the constraint module and then generate
       any .element or .attributes declarations.
       
       This is required by the DTD syntax rules which require
       all referenced parameter entities to occur before their
       first reference.
       
       Because constraint modules come before the modules
       they constrain they do not have access to any parameter
       entities defined in base modules.
       
       Note that this can result in redundant copies of 
       the same parameter entity in different constraint modules,
       but that isn't an issue for DTD parsing as the first
       declaration of a given parameter entity overrides any
       subsequent declarations.
       
       ==================================================== -->
  
  <xsl:template match="rng:grammar" mode="generate-referenced-parameter-entities">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] /**************************</xsl:message>
      <xsl:message>+ [DEBUG] generate-referenced-parameter-entities: Handling module doc "{base-uri(.)}"...</xsl:message>
      <xsl:message>+ [DEBUG]     have {count(.//rng:define[ends-with(@name, '.content') or ends-with(@name, '.attributes')])} content or attributes defines</xsl:message>
    </xsl:if>
    
    <!-- Process references within *.content and *.attributes patterns.
      
         If a pattern is defined in the current module, process its references.
         If a pattern is not in the current module, find it in one of the 
         modules to process and put it here, first processing any of its
         references.
         
         For each referenced non-local pattern, first determine the set of
         element types referenced so that we can create the element type
         name parameter entities for each referenced element type.
      -->
    
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] **** generate-referenced-parameter-entities: Collecting referenced element type entries...</xsl:message>      
    </xsl:if>

    <xsl:call-template name="gfpe-generate-element-type-name-parameter-entities">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug and false()"/>
    </xsl:call-template>
    
    <xsl:call-template name="gfpe-generate-parameter-entities">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug and false()"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="gfpe-generate-element-type-name-parameter-entities">    
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- Collecting these as a map so that we have some visibility into where each element type
         is declared, which might be useful for analysis, debugging, etc.
         
         But really all we need is the list of names.
         
      -->
    <xsl:variable name="referenced-element-type-entries" as="map(xs:string, element(rng:define)*)*">
      <xsl:apply-templates select=".//rng:define" mode="gfpe-collect-element-type-names">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug and false()"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <xsl:variable name="referenced-element-types-map" as="map(xs:string, element(rng:define)*)"
      select="map:merge($referenced-element-type-entries, map{ 'duplicates' : 'combine'})"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] **** generate-referenced-parameter-entities: referenced-element-types-map:</xsl:message>
      <xsl:for-each select="map:keys($referenced-element-types-map)">
        <xsl:message>+ [DEBUG]     "{.}" : {count(map:get($referenced-element-types-map, .))} defines </xsl:message>
      </xsl:for-each>
    </xsl:if>
    
    <xsl:for-each select="map:keys($referenced-element-types-map)">
      <xsl:sort select="."/>
      
      <xsl:text>&lt;!ENTITY % {str:pad(., 48)}"{.}"&gt;&#x0a;</xsl:text>
    </xsl:for-each>    
    
    <xsl:text>&#x0a;</xsl:text>    
  </xsl:template>
  
  <!-- ========================================
       gfpe-collect-element-type-names
       ======================================== -->
  
  <xsl:template mode="gfpe-collect-element-type-names" 
      match="rng:define[rng:ref[ends-with(@name, '.element')]]" 
      as="map(xs:string, element(rng:define)*)?"
      priority="10"
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>
    

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-collect-element-type-names:   Define {@name} is an element type</xsl:message>      
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="@name = $notAllowedPatternNames">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] gfpe-collect-element-type-names: define, name="{@name}" - Define is notAllowed, ignoring</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:map-entry key="xs:string(@name)">
          <xsl:sequence select="."/>
        </xsl:map-entry>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="gfpe-collect-element-type-names" match="rng:define" as="map(xs:string, element(rng:define)*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-collect-element-type-names: Define {@name}: processing its refs...</xsl:message>      
    </xsl:if>
    
    <xsl:choose>
      <xsl:when test="@name = $notAllowedPatternNames">
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] gfpe-collect-element-type-names: define, name="{@name}" - Define is notAllowed, ignoring</xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select=".//rng:ref" mode="#current">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>
  
  <xsl:template mode="gfpe-collect-element-type-names" 
    match="rng:ref[matches(@name, '^.+-d-.+$|\.element$')]" 
    as="map(xs:string, element(rng:define)*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- Ignore references to domain integration patterns and .element patterns -->
  </xsl:template>

  <xsl:template mode="gfpe-collect-element-type-names" match="rng:ref" as="map(xs:string, element(rng:define)*)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-collect-element-type-names: Handling ref "{@name}"...</xsl:message>
    </xsl:if>
    
    <xsl:variable name="targetName" as="xs:string" select="@name"/>
    
    <xsl:variable name="defines" as="element(rng:define)*"
      select="key('definesByName', $targetName)"
    />
    
    <xsl:variable name="defines" as="element(rng:define)*"
      select="
      if (empty($defines)) 
      then ($modulesToProcess ! key('definesByName', $targetName, .))
      else $defines"
    />
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-collect-element-type-names:    Ref to {$targetName}: Have {count($defines)} defines.</xsl:message>      
    </xsl:if>
    
    <xsl:apply-templates select="$defines" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>

  </xsl:template>
  
  <!-- ========================================
       Generate parameter entities (other than element type
       name parameter entities).
       
       Generate entities for each unique referenced
       pattern then generate entities for .content
       and .attributes patterns.
       ======================================== -->
  
  
  <xsl:template name="gfpe-generate-parameter-entities">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] **** gfpe-generate-parameter-entities: Collecting referenced patterns</xsl:message>      
    </xsl:if>
    
    <xsl:variable name="referenced-patterns" as="element(rng:define)*">
      <xsl:apply-templates select=".//rng:define" mode="gfpe-collect-referenced-patterns">
        <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
      </xsl:apply-templates>
    </xsl:variable>
    
    <!-- Use the first definition found of a given pattern. This should be the correct one.
      -->
    <xsl:variable name="referenced-pattern-names" as="xs:string*"
      select="$referenced-patterns ! xs:string(./@name) => distinct-values()"
    />

    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-generate-parameter-entities: referenced-patterns:</xsl:message>
      <xsl:message>+ [DEBUG]   {$referenced-pattern-names => string-join(', ')}</xsl:message>
    </xsl:if>
    
    <xsl:variable name="defines-to-process" as="element(rng:define)*"
    >
      <xsl:for-each select="$referenced-pattern-names">
        <xsl:variable name="name" as="xs:string" select="."/>
        <xsl:sequence select="($referenced-patterns[@name = $name])[1]"/>
      </xsl:for-each>      
    </xsl:variable>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] **** generate-referenced-parameter-entities: Processing defines to generate parameter entity decls...</xsl:message>  
      <xsl:message>+ [DEBUG]    defines-to-process:
<xsl:sequence select="$defines-to-process"/>      
      </xsl:message>
    </xsl:if>
    
    <!-- Construct parameter entities for the referenced patterns: -->
    
    <xsl:apply-templates mode="generate-parment-decl-from-define" 
      select="$defines-to-process"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>      

    <!-- Construct parameter entities for the .content and .attributes patterns in this module: -->
    
    <xsl:apply-templates mode="generate-parment-decl-from-define" 
      select=".//rng:define[ends-with(@name, '.content') or ends-with(@name, '.attributes')]"
      >
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] **** generate-referenced-parameter-entities: Parameter entity decls generated.</xsl:message>      
      <xsl:message>+ [DEBUG] **************************/</xsl:message>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template mode="gfpe-collect-referenced-patterns" 
    match="rng:define[ends-with(@name, '.content') or ends-with(@name, '.attributes')]"
    as="element(rng:define)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:apply-templates mode="#current" select=".//rng:ref">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug and false()"/>
    </xsl:apply-templates>
    
    <!-- Don't include these patterns in the referenced patterns list -->
  </xsl:template>
  
  <xsl:template mode="gfpe-collect-referenced-patterns" match="rng:define" as="element(rng:define)*">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:apply-templates mode="#current" select=".//rng:ref">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug and false()"/>
    </xsl:apply-templates>
    
    <xsl:sequence select="."/>
    
    
  </xsl:template>
  
  <!-- ========================================
       gfpe-defines-in-content-or-attributes
       ======================================== -->
  
  <!-- Ignore element type name and domain integration patterns -->
  <xsl:template 
    mode="
      gfpe-defines-in-content-or-attributes 
      gfpe-refs-in-content-or-attributes 
      gfpe-collect-referenced-patterns
    " 
    priority="10"
    match="
      rng:define[
        rng:ref[contains(@name, '.element')] or 
        rng:ref[matches(@name, '^.+-d-.+$')] or 
        matches(@name, '^.+-d-.+$')]
      " 
    >
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] various modes: Ignoring define {@name}</xsl:message>
    </xsl:if>
  </xsl:template>
  
  <xsl:template mode="gfpe-defines-in-content-or-attributes" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-defines-in-content-or-attributes: Handling define "{@name}"...</xsl:message>
    </xsl:if>
    
    <xsl:apply-templates select=".//rng:ref" mode="gfpe-refs-in-content-or-attributes"> 
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template 
    mode="
      gfpe-refs-in-content-or-attributes
      gfpe-collect-referenced-patterns
    " 
    match="rng:ref[matches(@name, '^.+-d-.+$|\.element$')]" priority="10">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- Ignore domain integration and element definition patterns -->
  </xsl:template>
  
  <xsl:template 
    mode="
      gfpe-refs-in-content-or-attributes 
      gfpe-collect-referenced-patterns
    " 
    match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-defines-in-content-or-attributes: Handling ref "{@name}"...</xsl:message>
    </xsl:if>
    
    <xsl:variable name="targetName" as="xs:string" select="@name"/>       
    
    <xsl:variable name="define" as="element(rng:define)?"
      select="key('definesByName', $targetName)[1]"
      />
    
    <xsl:variable name="define" as="element(rng:define)?"
      select="
        if (empty($define))
        then ($modulesToProcess ! key('definesByName', $targetName, .))[1]
        else $define
        "
    />
      
    <xsl:apply-templates select="$define" mode="#current">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template mode="gfpe-refs-in-content-or-attributes" match="rng:define">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    
    <!-- Must not be an element type name pattern, process it to generate parameter entity declaration -->
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-defines-in-content-or-attributes: define {@name}: calling generate-parment-decl-from-define...</xsl:message>
    </xsl:if>
    
    <xsl:apply-templates select=".//rng:ref" mode="gfpe-refs-in-other-modules">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
    </xsl:apply-templates>
    
    <xsl:apply-templates select="." mode="generate-parment-decl-from-define">
      <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    </xsl:apply-templates>
        
  </xsl:template>
  
  <xsl:template mode="gfpe-refs-in-other-modules" match="rng:ref">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="modulesToProcess" tunnel="yes" as="document-node()*"/>
    <xsl:param name="notAllowedPatterns" tunnel="yes" as="element(rng:define)*"/>    
    <xsl:param name="notAllowedPatternNames" tunnel="yes" as="xs:string*"/>
    
    <xsl:if test="$doDebug">
      <xsl:message>+ [DEBUG] gfpe-refs-in-other-modules: Handling ref "{@name}"...</xsl:message>
    </xsl:if>
    
    <xsl:variable name="targetName" as="xs:string" select="@name"/>
    
    <xsl:choose>
      <xsl:when test="$targetName = $notAllowedPatternNames">
        <xsl:message>+ [DEBUG] gfpe-refs-in-other-modules: rng:ref, name="{$targetName}" - Referenced define is notAllowed, ignoring.</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="defines" as="element(rng:define)*"
          select="key('definesByName', $targetName)"
        />
        
        <xsl:variable name="defines" as="element(rng:define)*"
          select="
            if (empty($defines)) 
            then ($modulesToProcess ! key('definesByName', $targetName, .))
            else $defines"
        />
        
        <xsl:if test="$doDebug">
          <xsl:message>+ [DEBUG] gfpe-refs-in-other-modules: targetName="{$targetName}", have {count($defines)} defines.</xsl:message>
        </xsl:if>
        
        <xsl:apply-templates select="$defines" mode="gfpe-refs-in-content-or-attributes">
          <xsl:with-param name="doDebug" as="xs:boolean" tunnel="yes" select="$doDebug"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>        
      
  </xsl:template>
  
 
</xsl:stylesheet>