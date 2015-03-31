<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:relpath="http://dita2indesign/functions/relpath"
  xmlns:local="urn:local-functions"
  xmlns:testing="urn:oasis-open:dita:testing"
  exclude-result-prefixes="xs xd relpath local testing"
  version="2.0">
  
  <!-- Test document generator. Generates schema-type-specific
       instances from files that have no associated schemas.

       Each document has two attributes on the root element:
       
       @shellPackage - Specifies the package the shell is in, e.g.
         "base", "technicalContent", etc.
       @shellName - Specifies the base name of the shell to use,
         e.g. "concept", "bookmap", etc.
         
       This information is then used to construct the appropriate
       DOCTYPE declaration, schemaLocation, or RNG grammar
       association.
       
       The input to the transform is a file in the root of the 
       directory tree containing the files to be processed. This
       file is required by Ant's XSLT task and simply serves to
       establish the directory tree to be processed.
       
       The files in the directory are processed using Saxon's
       collection() mechanism. The output files are generated
       relative to the specified output directory.
       
       The direct output of the transform is a manifest of the
       documents generated.
       
    -->
 
  <xsl:import href="../lib/relpath_util.xsl"/>


  <xsl:output 
    omit-xml-declaration="no" 
    indent="yes"
  />
  
  <xsl:output name="xml" omit-xml-declaration="no"/>
  
  <!-- The directory to put the output into. It must be
       specified since there is no useful default here.
    -->
  <xsl:param name="outdir" as="xs:string" required="yes"/>
  <xsl:param name="info" as="xs:string" select="'no'"/>
  <xsl:param name="debug" as="xs:string" select="'no'"/>
  <xsl:variable name="debugBoolean" as="xs:boolean"
    select="matches($debug, 'yes|true|1|on', 'i')"
  />
  <xsl:variable name="infoBoolean" as="xs:boolean"
    select="matches($info, 'yes|true|1|on', 'i') or 
            $debugBoolean"
  />
  
  <xsl:template match="/">
    <xsl:if test="$infoBoolean">
      <xsl:message> + [INFO] outdir="<xsl:value-of select="$outdir"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="baseInputDir" as="xs:string"
      select="relpath:getParent(document-uri(.))"
      />
    <xsl:if test="$infoBoolean">
      <xsl:message> + [INFO] base input directory="<xsl:value-of select="$baseInputDir"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="dtdOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'dtd'))"/>
    <xsl:variable name="rncUrlOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'rncUrl'))"/>
    <xsl:variable name="rncUrnOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'rncUrn'))"/>
    <xsl:variable name="rngUrlOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'rngUrl'))"/>
    <xsl:variable name="rngUrnOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'rngUrn'))"/>
    <xsl:variable name="xsdUrlOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'xsdUrl'))"/>
    <xsl:variable name="xsdUrnOutDir" as="xs:string" select="relpath:toUrl(relpath:newFile($outdir, 'xsdUrn'))"/>

    
    <xsl:variable name="collectionUrl" as="xs:string"
      select="concat($baseInputDir, 
      '?',
      'recurse=yes;',      
      'on-error=warning;',
      'select=*.(dita|ditamap|xml|ditaval);'
      )"
    />
  
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] collectionUrl="<xsl:sequence select="$collectionUrl"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="docsToProcess" as="document-node()*"     
      select="collection(iri-to-uri($collectionUrl))"
    />
    <xsl:if test="false() and $debugBoolean">
      <xsl:message> + [DEBUG] Files to process: 
        <xsl:sequence select="for $doc in $docsToProcess return concat(document-uri($doc), '&#x0a;')"/>
      </xsl:message>
    </xsl:if>

     <doc-generation-manifest
       timestamp="{current-dateTime()}"
       collectionUri="{$collectionUrl}"
       >
       
       <xsl:apply-templates select="$docsToProcess" mode="generateTestFiles">
        <xsl:with-param name="dtdOutDir" select="$dtdOutDir" as="xs:string"/>
         <xsl:with-param name="rncUrlOutDir" select="$rncUrlOutDir" as="xs:string"/>
         <xsl:with-param name="rncUrnOutDir" select="$rncUrnOutDir" as="xs:string"/>
         <xsl:with-param name="rngUrlOutDir" select="$rngUrlOutDir" as="xs:string"/>
        <xsl:with-param name="rngUrnOutDir" select="$rngUrnOutDir" as="xs:string"/>
        <xsl:with-param name="xsdUrlOutDir" select="$xsdUrlOutDir" as="xs:string"/>
        <xsl:with-param name="xsdUrnOutDir" select="$xsdUrnOutDir" as="xs:string"/>       
       </xsl:apply-templates>
     </doc-generation-manifest>
  </xsl:template>
  
  <xsl:template mode="generateTestFiles" match="/">
    <!-- The context node for this template is the document node
         for a base test document.
      -->
    <xsl:param name="dtdOutDir" as="xs:string"/>
    <xsl:param name="rncUrlOutDir" as="xs:string"/>
    <xsl:param name="rncUrnOutDir" as="xs:string"/>
    <xsl:param name="rngUrlOutDir" as="xs:string"/>
    <xsl:param name="rngUrnOutDir" as="xs:string"/>
    <xsl:param name="xsdUrlOutDir" as="xs:string"/>
    <xsl:param name="xsdUrnOutDir" as="xs:string"/>
    
    <xsl:variable name="docUri" select="string(document-uri(.))" as="xs:string"/>
    <xsl:if test="$infoBoolean">
      <xsl:message> + [INFO] Handling doc <xsl:value-of select="$docUri"/></xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="contains($docUri, '/media/')">
        <!-- Skip this file -->
      </xsl:when>
      <xsl:otherwise>
        
        <xsl:variable name="baseName" select="relpath:getNamePart($docUri)"/>
        <xsl:variable name="ext" select="relpath:getExtension($docUri)"/>
        
        <xsl:variable name="package" select="/*/@shellPackage" as="xs:string?"/>
        <xsl:if test="not($package)">
          <xsl:message terminate="yes"> - [ERROR] No value for @shellPackage in document <xsl:value-of select="$docUri"/></xsl:message>
        </xsl:if>
        
        <xsl:variable name="dtdResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($dtdOutDir, $package), concat($baseName, '.dtd.', $ext))"
          />
        <xsl:variable name="rncUrnResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($rncUrnOutDir, $package), concat($baseName, '.rncurn.', $ext))"
          />
        <xsl:variable name="rncUrlResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($rncUrlOutDir, $package), concat($baseName, '.rncurl.', $ext))"
          />
        <xsl:variable name="rngUrnResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($rngUrnOutDir, $package), concat($baseName, '.rngurn.', $ext))"
        />
        <xsl:variable name="rngUrlResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($rngUrlOutDir, $package), concat($baseName, '.rngurl.', $ext))"
        />
        <xsl:variable name="xsdUrnResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($xsdUrnOutDir, $package), concat($baseName, '.xsdurn.', $ext))"
          />
        <xsl:variable name="xsdUrlResultUri" as="xs:string"
          select="relpath:newFile(relpath:newFile($xsdUrlOutDir, $package), concat($baseName, '.xsdurl.', $ext))"
          />
        
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$dtdResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'dtd'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$rncUrlResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'rncurl'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$rncUrnResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'rncurn'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$rngUrlResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'rngurl'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$rngUrnResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'rngurn'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$xsdUrlResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'xsdurl'" as="xs:string"/>
        </xsl:call-template>
        <xsl:call-template name="generateTestDoc">
          <xsl:with-param name="resultUri" select="$xsdUrnResultUri" as="xs:string"/>
          <xsl:with-param name="schemaType" select="'xsdurn'" as="xs:string"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="generateTestDoc">
    <!-- Context node is the document node for a base test document -->
    <xsl:param name="resultUri" as="xs:string"/>
    <xsl:param name="schemaType" as="xs:string"/>
    <xsl:if test="$infoBoolean">
      <xsl:message> + [INFO]  Generating <xsl:value-of select="$schemaType"/> document <xsl:value-of select="$resultUri"/></xsl:message>
    </xsl:if>
    <doc uri="{$resultUri}"
         schemaType="{$schemaType}"
      />
    <xsl:choose>
      <xsl:when test="$schemaType = 'dtd'">
        <xsl:result-document href="{$resultUri}" format="xml"
            doctype-public="{local:getDtdPubId(.)}"
            doctype-system="{local:getDtdSysId(.)}"
          >
          <xsl:apply-templates mode="copy" select="node()">
            <xsl:with-param name="schemaType" as="xs:string" select="$schemaType" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:result-document>
      </xsl:when>
      <xsl:when test="$schemaType = 'xsdurl'">
        <xsl:result-document href="{$resultUri}" format="xml"
          >
          <xsl:apply-templates mode="copy" select="node()">
            <xsl:with-param name="schemaType" as="xs:string" select="$schemaType" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:result-document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:result-document href="{$resultUri}" format="xml">
          <xsl:apply-templates mode="copy" select="node()">
            <xsl:with-param name="schemaType" as="xs:string" select="$schemaType" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:result-document>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="copy" match="/*">
    <xsl:param name="schemaType" as="xs:string" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$schemaType = 'rngurl'">
        <xsl:text>&#x0a;</xsl:text><xsl:processing-instruction name="xml-model">
          <xsl:text>href="</xsl:text><xsl:value-of select="local:getRngUrl(root(.))"/><xsl:text>"
      type="application/xml" 
      schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text>
        </xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
      </xsl:when>
      <xsl:when test="$schemaType = 'rngurn'">
        <xsl:text>&#x0a;</xsl:text><xsl:processing-instruction name="xml-model">
          <xsl:text>href="</xsl:text><xsl:value-of select="local:getRngUrn(root(.))"/><xsl:text>"
      type="application/relax-ng-compact-syntax" 
      schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text>
        </xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
      </xsl:when>
      <xsl:when test="$schemaType = 'rncurl'">
        <xsl:text>&#x0a;</xsl:text><xsl:processing-instruction name="xml-model">
          <xsl:text>href="</xsl:text><xsl:value-of select="local:getRncUrl(root(.))"/><xsl:text>"
      type="application/relax-ng-compact-syntax"</xsl:text>
        </xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
      </xsl:when>
      <xsl:when test="$schemaType = 'rncurn'">
        <xsl:text>&#x0a;</xsl:text><xsl:processing-instruction name="xml-model">
          <xsl:text>href="</xsl:text><xsl:value-of select="local:getRncUrn(root(.))"/><xsl:text>"
      type="application/relax-ng-compact-syntax"</xsl:text>
        </xsl:processing-instruction><xsl:text>&#x0a;</xsl:text>
      </xsl:when>
      <xsl:otherwise><!-- Nothing to do --></xsl:otherwise>
    </xsl:choose>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$schemaType = 'xsdurl'">
          <xsl:attribute 
            name="xsi:noNamespaceSchemaLocation" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            select="local:getSchemaUrl(root(.))"
          />
        </xsl:when>
        <xsl:when test="$schemaType = 'xsdurn'">
          <xsl:attribute 
            name="xsi:noNamespaceSchemaLocation" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            select="local:getSchemaUrn(root(.))"
          />
        </xsl:when>
        <xsl:otherwise><!-- nothing to do --></xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="@* except (@shellPackage, @shellName)" mode="#current"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="copy" match="testing:entityref">
    <xsl:param name="schemaType" as="xs:string" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="$schemaType = 'dtd'">
        <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="#current" select="node()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template mode="copy" match="*" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template mode="copy" match="@* | processing-instruction() | comment() | text()">
    <xsl:sequence select="."/>
  </xsl:template>
  
  <xsl:function name="local:getDtdPubId" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getDtdPubId: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getDtdPubId: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <xsl:variable name="key" as="xs:string"
      select="concat($shellPackage, '/', $shellName)"
    />
<!--    <xsl:message> + [DEBUG] local:getDtdPubId: key="<xsl:value-of select="$key"/>"</xsl:message>-->
    <xsl:variable name="shellMap" as="document-node()"
      select="document('shell2pubidMap.xml')"
    />
    <xsl:variable name="pubId" as="xs:string?"
      select="$shellMap/*/mapitem[@key = $key]/@dtdPubId"
    />
    <xsl:if test="$pubId = ''">
      <xsl:message> - [WARN] local:getDtdPubId: Failed to find an entry for key "<xsl:sequence select="$key"/>" in <xsl:value-of select="document-uri($shellMap)"/></xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string"
      select="if ($pubId) then $pubId else 'PubID not found'"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <xsl:function name="local:getDtdSysId" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellName" as="xs:string"
      select="string($doc/*/@shellName)"
    />
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] local:getDtdSysId: key="<xsl:value-of select="$shellName"/>"</xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string"
      select="concat($shellName, '.dtd')"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <xsl:function name="local:getSchemaUrl" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getSchemaUrl: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getSchemaUrl: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <!-- NOTE: This code presumes/depends on consistent relative locations for the test
         document and the generated XSDs. If that can't be dependedn on, will need to
         pass in the root folder for the XSDs so we can construct absolute URLs and then
         use relpath functions to construct a working relative URL from the test doc
         to the XSD.
      -->
    <xsl:variable name="basePath" as="xs:string" select="'../../../../schema-url/'"/>
    <xsl:variable name="packageAndFile" as="xs:string" 
      select="concat($shellPackage, '/xsd/', $shellName, '.xsd')"/>
    <xsl:variable name="result" as="xs:string"
      select="concat($basePath, $packageAndFile)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="local:getRngUrl" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getRngUrl: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getRngUrl: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <!-- NOTE: This code presumes/depends on consistent relative locations for the test
         document and the generated XSDs. If that can't be dependedn on, will need to
         pass in the root folder for the XSDs so we can construct absolute URLs and then
         use relpath functions to construct a working relative URL from the test doc
         to the XSD.
      -->
    <xsl:variable name="basePath" as="xs:string" select="'../../../../rng/'"/>
    <xsl:variable name="packageAndFile" as="xs:string" 
      select="concat($shellPackage, '/rng/', $shellName, '.rng')"/>
    <xsl:variable name="result" as="xs:string"
      select="concat($basePath, $packageAndFile)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="local:getRncUrl" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getRncUrl: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getRncUrl: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <!-- NOTE: This code presumes/depends on consistent relative locations for the test
         document and the generated RNCs. If that can't be dependedn on, will need to
         pass in the root folder for the RNCs so we can construct absolute URLs and then
         use relpath functions to construct a working relative URL from the test doc
         to the RNC.
      -->
    <xsl:variable name="basePath" as="xs:string" select="'../../../../rnc/'"/>
    <xsl:variable name="packageAndFile" as="xs:string" 
      select="concat($shellPackage, '/rnc/', $shellName, '.rnc')"/>
    <xsl:variable name="result" as="xs:string"
      select="concat($basePath, $packageAndFile)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="local:getSchemaUrn" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getSchemaUrl: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getSchemaUrl: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <xsl:variable name="key" as="xs:string"
      select="concat($shellPackage, '/', $shellName)"
    />
    <!--    <xsl:message> + [DEBUG] local:getDtdPubId: key="<xsl:value-of select="$key"/>"</xsl:message>-->
    <xsl:variable name="shellMap" as="document-node()"
      select="document('shell2pubidMap.xml')"
    />
    <xsl:variable name="urn" as="xs:string?"
      select="$shellMap/*/mapitem[@key = $key]/@xsdUrn"
    />
    <xsl:if test="$urn = ''">
      <xsl:message> - [WARN] local:getSchemaUrn: Failed to find an entry for key "<xsl:sequence select="$key"/>" in <xsl:value-of select="document-uri($shellMap)"/></xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string"
      select="$urn"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="local:getRngUrn" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getRngUrn: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getRngUrn: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <xsl:variable name="key" as="xs:string"
      select="concat($shellPackage, '/', $shellName)"
    />
    <!--    <xsl:message> + [DEBUG] local:getRngUrn: key="<xsl:value-of select="$key"/>"</xsl:message>-->
    <xsl:variable name="shellMap" as="document-node()"
      select="document('shell2pubidMap.xml')"
    />
    <xsl:variable name="urn" as="xs:string?"
      select="$shellMap/*/mapitem[@key = $key]/@rngUrn"
    />
    <xsl:if test="$urn = ''">
      <xsl:message> - [WARN] local:getRngUrn: Failed to find an entry for key "<xsl:sequence select="$key"/>" in <xsl:value-of select="document-uri($shellMap)"/></xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string"
      select="$urn"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
  <xsl:function name="local:getRncUrn" as="xs:string">
    <xsl:param name="doc" as="document-node()"/>
    <xsl:variable name="shellPackage" as="xs:string" select="$doc/*/@shellPackage"/>
    <xsl:variable name="shellName" as="xs:string" select="$doc/*/@shellName"/>
    <xsl:if test="$shellPackage = ''">
      <xsl:message> - [WARN] local:getRncUrn: No value for @shellPackage attribute.</xsl:message>      
    </xsl:if>
    <xsl:if test="$shellName = ''">
      <xsl:message> - [WARN] local:getRncUrn: No value for @shellName attribute.</xsl:message>      
    </xsl:if>
    <xsl:variable name="key" as="xs:string"
      select="concat($shellPackage, '/', $shellName)"
    />
    <!--    <xsl:message> + [DEBUG] local:getRncUrn: key="<xsl:value-of select="$key"/>"</xsl:message>-->
    <xsl:variable name="shellMap" as="document-node()"
      select="document('shell2pubidMap.xml')"
    />
    <xsl:variable name="urn" as="xs:string?"
      select="$shellMap/*/mapitem[@key = $key]/@rncUrn"
    />
    <xsl:if test="not(boolean($urn)) or $urn = ''">
      <xsl:message> - [WARN] local:getRncUrn: Failed to find an entry for key "<xsl:sequence select="$key"/>" in <xsl:value-of select="document-uri($shellMap)"/></xsl:message>
    </xsl:if>
    <xsl:variable name="result" as="xs:string"
      select="$urn"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>
  
</xsl:stylesheet>