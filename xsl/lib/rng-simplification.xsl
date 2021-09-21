<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://relaxng.org/ns/structure/1.0" 
  xmlns:rng="http://relaxng.org/ns/structure/1.0" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:local="http://local-functions"
exclude-result-prefixes = "xs rng local"
expand-text="yes"
  >
  <!-- ===============================================
       RNG Simplification transform
       
       See http://relaxng.org/spec-20011203.html#simplification
       
       Originally implemented by Eric van der Vlist
       
       Upgraded to XSLT 2 by W. Eliot Kimber:
       
         - Changed 7.x to 4.x to reflect final RNG spec.
         - Generally use XSLT 2 constructs and practice 
       
       =============================================== -->

<xsl:output method="xml"
  indent="yes"
/>
  
<xsl:output name="intermediate-result"
  method="xml"
  indent="yes"
/>

<xsl:strip-space elements="*"/>

<xsl:param name="out-name" select="'simplified'" as="xs:string"/>
  
<xsl:template match="/">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
  <xsl:apply-templates select="." mode="rng-simplification">
    <xsl:with-param name="out" select="$out" as="xs:boolean"/>
  </xsl:apply-templates>
</xsl:template>

<!-- 4.2. Whitespace-->

<xsl:template match="/" mode="rng-simplification">  
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.2. Whitespace</xsl:message>
	<xsl:comment>4.2 Whitespace</xsl:comment>
	<xsl:variable name="step" as="document-node()">
	  <xsl:document><xsl:apply-templates mode="step4.02"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-02.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.2'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.03"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			  <!-- FIXME: Won't need this once xml:base is set on root elements of intermediate docs. -->
        <!-- We need this for resolving references later in the process
             where we're operating on internal nodes where the base
             URI is the XSLT transform itself.
          -->
			  <xsl:with-param name="origDoc" select="." as="document-node()" tunnel="yes"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rng:*" mode="step4.02">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.02"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*[namespace-uri()='']" mode="step4.02">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="*|@*" mode="step4.02" priority="-1"/>

<!-- 4.3 datatypeLibrary attribute -->

<xsl:template match="/" mode="step4.03">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.3. datatypeLibrary attribute</xsl:message>
	<xsl:comment>4.3</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.03"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-03.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.3'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.04">
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.03">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.03"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="@*|text()" mode="step4.03" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="text()[normalize-space(.)='' and not(parent::rng:param or parent::rng:value)]" mode="step4.03"/>

<xsl:template match="@name|@type|@combine" mode="step4.03">
	<xsl:attribute name="{name(.)}" select="normalize-space(.)"/>
</xsl:template>

<xsl:template match="rng:name/text()" mode="step4.03">
	<xsl:sequence select="normalize-space(.)"/>
</xsl:template>

<!-- 4.4 type attribute of value element -->

<xsl:template match="/" mode="step4.04">
  <xsl:param name="out" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.4. type attribute of value element</xsl:message>
	<xsl:comment>4.4</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.04"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-04.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.4'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.05"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.04" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.04"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.04" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="@datatypeLibrary" mode="step4.04"/>

<xsl:template match="rng:data|rng:value" mode="step4.04">
	<xsl:copy>
		<xsl:attribute name="datatypeLibrary"
		  select="ancestor-or-self::*[@datatypeLibrary][1]/@datatypeLibrary"
		/>
		<xsl:apply-templates select="@*, node()" mode="step4.04"/>
	</xsl:copy>
</xsl:template>

<!-- 4.5 href attribute -->

<xsl:template match="/" mode="step4.05">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.5. href attribute</xsl:message>
	<xsl:comment>4.5</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.05"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-05.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.5'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.06"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.05" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.05"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.05" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:value[not(@type)]/@datatypeLibrary" mode="step4.05"/>

<xsl:template match="rng:value[not(@type)]" mode="step4.05">
	<value type="token" datatypeLibrary="">
		<xsl:apply-templates select="@*, node()" mode="step4.05"/>
	</value>
</xsl:template>

<!-- 4.6 externalRef element -->
  
<xsl:template match="/" mode="step4.06">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.6. externalRef element</xsl:message>
	<xsl:comment>4.6</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.06"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-06.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.6'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.07"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.06" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.06"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.06" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>


<xsl:template match="rng:externalRef" mode="step4.06">
  <!-- FIXME: Won't need this once xml:base is set on root elements of intermediate docs. -->  
  <xsl:param name="origDoc" tunnel="yes" as="document-node()"/>
  
  <xsl:variable name="uriRef" as="xs:string" select="@href"/>
  <xsl:message> + [DEBUG]] rng:externalRef: uriRef = "<xsl:sequence select="$uriRef"/>"</xsl:message>
  <xsl:variable name="includedDoc" as="document-node()?" 
    select="document($uriRef, $origDoc)"
  />
	  <xsl:choose>
	    <xsl:when test="not($includedDoc)">
	      <xsl:message> + [ERROR] Failed to resolve reference to included document "<xsl:sequence select="$uriRef"/> relative
       to base URI "<xsl:sequence select="base-uri($includedDoc)"/>"</xsl:message>
	    </xsl:when>
	    <xsl:otherwise>
      	<xsl:variable name="ref" as="node()*">
      	  <xsl:apply-templates select="$includedDoc">
      			<xsl:with-param name="out" select="false()" as="xs:boolean"/>
      			<xsl:with-param name="stop-after" select="'step4.7'"/>
      		</xsl:apply-templates>
      	</xsl:variable>
      	<xsl:element name="{local-name($ref/*)}" namespace="http://relaxng.org/ns/structure/1.0">
      		<xsl:if test="not($ref/*/@ns) and @ns">
      		  <xsl:sequence select="@ns"/>
      		</xsl:if>
      		<xsl:sequence select="$ref/*/@*"/>
      		<xsl:sequence select="$ref/*/*|$ref/*/text()"/>
      	</xsl:element>
	    </xsl:otherwise>
	  </xsl:choose>
</xsl:template>

<!-- 4.7 Include element  -->

<xsl:template match="/" mode="step4.07">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.7. include element</xsl:message>
	<xsl:comment>4.7</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.07"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-07.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.7'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.08"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.07" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.07"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.07" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>


<xsl:template match="rng:include" mode="step4.07">
  <!-- FIXME: Won't need this once xml:base is set on root elements of intermediate docs. -->
  <xsl:param name="origDoc" as="document-node()" tunnel="yes"/>

  <xsl:variable name="uriRef" as="xs:string" select="@href"/>
  <xsl:message> + [INFO] ======</xsl:message>
  <xsl:message> + [INFO] Processing included schema "<xsl:sequence select="$uriRef"/>"</xsl:message>
  <xsl:message> + [INFO] ======</xsl:message>
  <xsl:variable name="doc" select="document($uriRef, $origDoc)" as="document-node()?"/>
  <xsl:choose>
    <xsl:when test="not($doc)">
      <xsl:message> + [ERROR] Failed to resolve @href "<xsl:sequence select="$uriRef"/>" for base URI 
        "<xsl:sequence select="base-uri($origDoc)"/>"</xsl:message>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="ref" as="node()*">
        <xsl:document>
      		<xsl:apply-templates select="$doc">
      			<xsl:with-param name="out" select="false()" as="xs:boolean"/>
      			<xsl:with-param name="stop-after" select="'step4.8'"/>
      		</xsl:apply-templates>
        </xsl:document>
    	</xsl:variable>
    	<div>
    		<xsl:sequence select="@*[name() != 'href']"/>
    		<xsl:sequence select="*"/>
    	  <!-- These two work (in that stuff from the included grammar shows up) but
    	       I don't know if they are correct because they are not as constrained
    	       as the original.
    	    -->
    	  <xsl:sequence select="$ref/rng:grammar/rng:start[not(current()/rng:start)]"/>
    	  <xsl:sequence select="$ref/rng:grammar/* except (rng:start)"/>
<!--
    	    This is the original from Eric, which selects nothing in my tests:
    	    
    	    <xsl:sequence select="$ref/rng:grammar/rng:start[not(current()/rng:start)]"/>
    		<xsl:sequence select="$ref//rng:grammar/rng:define[not(@name = current()/rng:define/@name)]"/>
-->    	</div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- 4.8 name attribute of element and attribute elements -->

<xsl:template match="/" mode="step4.08">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.8. name attribute of element and attribute elements</xsl:message>
	<xsl:comment>4.8</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.08"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-08.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.8'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.09"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.08" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.08"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.08" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="@name[parent::rng:element|parent::rng:attribute]" mode="step4.08"/>

<xsl:template match="rng:element[@name]|rng:attribute[@name]" mode="step4.08">
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.08"/>
		<xsl:if test="self::rng:attribute and not(@ns)">
			<xsl:attribute name="ns"/>
		</xsl:if>
		<name>{@name}</name>
		<xsl:apply-templates mode="step4.08"/>
	</xsl:copy>
</xsl:template>

<!-- 4.9 ns attribute -->

<xsl:template match="/" mode="step4.09">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.9. ns attribute</xsl:message>
	<xsl:comment>4.9</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.09"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-09.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.09'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.10"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.09" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.09"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.09" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="@ns" mode="step4.09"/>

<xsl:template match="rng:name|rng:nsName|rng:value" mode="step4.09">
	<xsl:copy>
		<xsl:attribute name="ns" select="ancestor-or-self::*[@ns][1]/@ns"/>
		<xsl:apply-templates select="@*, node()" mode="step4.09"/>
	</xsl:copy>
</xsl:template>

<!-- 4.10 QNames -->

<xsl:template match="/" mode="step4.10">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.10. QNames</xsl:message>
	<xsl:comment>4.10. QNames</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.10"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-10.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.10'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.11"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.10" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.10"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.10" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:name[contains(., ':')]" mode="step4.10">
	<xsl:variable name="prefix" select="substring-before(., ':')" as="xs:string"/>
	<name>
		<xsl:attribute name="ns" select="string(namespace::*[name(.) = $prefix])"/>
		{substring-after(., ':')}
	</name>
</xsl:template>

<!-- 4.11. div element -->

<xsl:template match="/" mode="step4.11">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.11. div element</xsl:message>
	<xsl:comment>4.11. div element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.11"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-11.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.11'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.12"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.11" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.11"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.11" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:div" mode="step4.11">
	<xsl:apply-templates mode="step4.11"/>
</xsl:template>

<!-- 4.12. Number of child elements -->

<xsl:template match="/" mode="step4.12">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.12. Number of child elements</xsl:message>
	<xsl:comment>4.12. Number of child elements</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.12"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-12.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.12'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.13"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.12" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.12"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.12" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>


<xsl:template
    mode="step4.12"
  match="
  rng:define[count(*)>1]|
  rng:oneOrMore[count(*)>1]|
  rng:zeroOrMore[count(*)>1]|
  rng:optional[count(*)>1]|
  rng:list[count(*)>1]|
  rng:mixed[count(*)>1]" 
  >
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.12"/>
		<xsl:call-template name="reduce7.13">
			<xsl:with-param name="node-name" select="'group'" as="xs:string"/>
		</xsl:call-template>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:except[count(*) > 1]" mode="step4.12">
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.12"/>
		<xsl:call-template name="reduce7.13">
			<xsl:with-param name="node-name" select="'choice'" as="xs:string"/>
		</xsl:call-template>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:attribute[count(*) = 1]" mode="step4.12">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.12"/>
		<text/>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:element[count(*) > 2]" mode="step4.12">
	<xsl:copy>
		<xsl:apply-templates select="@*, *[1]" mode="step4.12"/>
		<xsl:call-template name="reduce7.13">
			<xsl:with-param name="left" select="*[4]" as="node()*"/>
			<xsl:with-param name="node-name" select="'group'" as="xs:string"/>
			<xsl:with-param name="out" as="node()*">
				<group>
					<xsl:apply-templates select="*[2], *[3]" mode="step4.12"/>
				</group>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:copy>
</xsl:template>

<xsl:template  mode="step4.12"
  match="
  rng:group[count(*)=1]|
  rng:choice[count(*)=1]|
  rng:interleave[count(*)=1]"
  >
	<xsl:apply-templates select="*" mode="step4.12"/>
</xsl:template>

<xsl:template mode="step4.12" name="reduce7.13"
  match="
  rng:group[count(*)>2]|
  rng:choice[count(*)>2]|
  rng:interleave[count(*)>2]">
	<xsl:param name="left" select="*[3]" as="node()*"/>
	<xsl:param name="node-name" select="name()" as="xs:string"/>
	<xsl:param name="out" as="node()*">
		<xsl:element name="{$node-name}">
			<xsl:apply-templates select="*[1], *[2]" mode="step4.12"/>
		</xsl:element>
	</xsl:param>
	<xsl:choose>
		<xsl:when test="$left">
			<xsl:variable name="newOut">
				<xsl:element name="{$node-name}">
					<xsl:sequence select="$out"/>
					<xsl:apply-templates select="$left" mode="step4.12"/>
				</xsl:element>
			</xsl:variable>
			<xsl:call-template name="reduce7.13">
				<xsl:with-param name="left" select="$left/following-sibling::*[1]" as="node()*"/>
				<xsl:with-param name="out" select="$newOut" as="node()*"/>
				<xsl:with-param name="node-name" select="$node-name" as="xs:string"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="$out"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- 4.13. mixed element -->

<xsl:template match="/" mode="step4.13">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.13. mixed element</xsl:message>
	<xsl:comment>4.13. mixed element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.13"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-13.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.13'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.14"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.13" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.13"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.13" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:mixed" mode="step4.13">
	<interleave>
		<xsl:apply-templates mode="step4.13"/>
		<text/>
	</interleave>
</xsl:template>

<!-- 4.14. optional element -->

<xsl:template match="/" mode="step4.14">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.14. optional element</xsl:message>
	<xsl:comment>4.14. optional element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.14"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-14.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.14'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.15"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.14" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.14"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.14" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:optional" mode="step4.14">
	<choice>
		<xsl:apply-templates mode="step4.14"/>
		<empty/>
	</choice>
</xsl:template>

<!-- 4.15. zeroOrMore element -->

<xsl:template match="/" mode="step4.15">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.15. zeroOrMore element</xsl:message>
	<xsl:comment>4.15. zeroOrMore element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.15"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-15.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.15'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
		  <!-- NOTE: Step 4.16 is not relevant so we go straight to 4.17 -->
			<xsl:apply-templates select="$step" mode="step4.17"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.15" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.15"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.15" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="rng:zeroOrMore" mode="step4.15">
	<choice>
		<oneOrMore>
			<xsl:apply-templates mode="step4.15"/>
		</oneOrMore>
		<empty/>
	</choice>
</xsl:template>

<!-- 4.16, Constraints: No transformation. Not bothering to check constraints. -->

<!-- 4.17. combine attribute -->

<xsl:template match="/" mode="step4.17">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
  <xsl:message> + [INFO] Step 4.17. combine attribute</xsl:message>
	<xsl:comment>4.17. combine attribute</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.17"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-17.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.17'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.18"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.17" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.17"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.17" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="@combine" mode="step4.17"/>
<xsl:template match="rng:start[preceding-sibling::rng:start]|rng:define[@name=preceding-sibling::rng:define/@name]" mode="step4.17"/>

<xsl:template match="rng:start[not(preceding-sibling::rng:start) and following-sibling::rng:start]" mode="step4.17">
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.17"/>
		<xsl:element name="{parent::*/rng:start/@combine}">
			<xsl:call-template name="start7.18"/>
		</xsl:element>
	</xsl:copy>
</xsl:template>

<xsl:template name="start7.18">
	<xsl:param name="left" select="following-sibling::rng:start[2]" as="node()*"/>
	<xsl:param name="node-name" select="parent::*/rng:start/@combine" as="xs:string"/>
	<xsl:param name="out" as="node()*">
		<xsl:element name="{$node-name}">
			<xsl:apply-templates select="*" mode="step4.17"/>
			<xsl:apply-templates select="following-sibling::rng:start[1]/*" mode="step4.17"/>
		</xsl:element>
	</xsl:param>
	<xsl:choose>
		<xsl:when test="$left/*">
			<xsl:variable name="newOut" as="node()*">
				<xsl:element name="{$node-name}">
					<xsl:sequence select="$out"/>
					<xsl:apply-templates select="$left/*" mode="step4.17"/>
				</xsl:element>
			</xsl:variable>
			<xsl:call-template name="start7.18">
				<xsl:with-param name="left" select="$left/following-sibling::rng:start[1]" as="node()*"/>
				<xsl:with-param name="node-name" select="$node-name" as="xs:string"/>
				<xsl:with-param name="out" select="$newOut" as="node()*"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="$out"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template mode="step4.17" 
  match="rng:define[not(@name=preceding-sibling::rng:define/@name) and 
                    @name=following-sibling::rng:define/@name]" >
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.17"/>
		<xsl:call-template name="define7.18"/>
	</xsl:copy>
</xsl:template>

<xsl:template name="define7.18">
	<xsl:param name="left" select="following-sibling::rng:define[@name=current()/@name][2]" as="node()*"/>
	<xsl:param name="node-name" select="(parent::*/rng:define[@name=current()/@name]/@combine)[1]" as="xs:string"/>
	<xsl:param name="out" as="node()*">
		<xsl:element name="{$node-name}">
			<xsl:apply-templates select="*" mode="step4.17"/>
			<xsl:apply-templates select="following-sibling::rng:define[@name=current()/@name][1]/*" mode="step4.17"/>
		</xsl:element>
	</xsl:param>
	<xsl:choose>
		<xsl:when test="$left/*">
			<xsl:variable name="newOut" as="node()*">
				<xsl:element name="{$node-name}">
					<xsl:copy-of select="$out"/>
					<xsl:apply-templates select="$left/*" mode="step4.17"/>
				</xsl:element>
			</xsl:variable>
			<xsl:call-template name="define7.18">
				<xsl:with-param name="left" select="$left/following-sibling::rng:define[@name=current()/@name][1]" as="node()*"/>
				<xsl:with-param name="node-name" select="$node-name" as="xs:string"/>
				<xsl:with-param name="out" select="$newOut" as="node()*"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="$out"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- 4.18. grammar element -->

<xsl:template match="/" mode="step4.18">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.18. grammar element</xsl:message>
	<xsl:comment>4.18. grammar element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.18"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-18.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.18'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.19"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.18" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.18"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.18" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="/rng:grammar" mode="step4.18" priority="10">
	<grammar>
		<xsl:apply-templates mode="step4.18"/>
		<xsl:apply-templates select="//rng:define" mode="step4.19-define"/>
	</grammar>
</xsl:template>

<xsl:template match="/*" mode="step4.18">
	<grammar>
		<start>
			<xsl:copy>
				<xsl:apply-templates select="@*, node()" mode="step4.18"/>
			</xsl:copy>
		</start>
	</grammar>
</xsl:template>

<xsl:template match="rng:define|rng:define/@name|rng:ref/@name" mode="step4.18"/>

<xsl:template match="rng:define" mode="step4.19-define">
	<xsl:copy>
		<xsl:attribute name="name"  select="concat(@name, '-', generate-id())"/>
		<xsl:apply-templates select="@*, node()" mode="step4.18"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:grammar" mode="step4.18">
	<xsl:apply-templates select="rng:start/*" mode="step4.18"/>
</xsl:template>

<xsl:template match="rng:ref" mode="step4.18">
	<xsl:copy>
		<xsl:attribute name="name"
		   select="concat(@name, '-', generate-id(ancestor::rng:grammar[1]/rng:define[string(@name)=string(current()/@name)]))"
		 />
		<xsl:apply-templates select="@*, node()" mode="step4.18"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:parentRef" mode="step4.18">
	<ref>
		<xsl:attribute name="name"
		  select="concat(@name, '-', generate-id(ancestor::rng:grammar[2]/rng:define[@name=current()/@name]))"
		/>
		<xsl:apply-templates select="@*, node()" mode="step4.18"/>
	</ref>
</xsl:template>

<!-- 4.19. define and ref elements -->

<xsl:template match="/" mode="step4.19">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''" as="xs:string"/>
  <xsl:message> + [INFO] Step 4.19. define and ref elements</xsl:message>
	<xsl:comment>4.19. define and ref elements</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.19"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-19.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="$stop-after = 'step4.19'">
			<xsl:sequence select="$step"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="$step" mode="step4.21"> 
				<xsl:with-param name="out" select="$out" as="xs:boolean"/>
				<xsl:with-param name="stop-after" select="$stop-after" as="xs:string"/>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="*" mode="step4.19" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*" mode="step4.19"/>
		<xsl:apply-templates mode="step4.19"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.19" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="/rng:grammar" mode="step4.19">
	<xsl:copy>
		<xsl:apply-templates select="@*, node()" mode="step4.19"/>
		<xsl:apply-templates select="//rng:element[not(parent::rng:define)]" mode="step4.20-define"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:element" mode="step4.20-define">
	<define name="{local:constructDefineName(.)}">
		<xsl:copy>
			<xsl:apply-templates select="@*, node()" mode="step4.19"/>
		</xsl:copy>
	</define>
</xsl:template>

<xsl:template match="rng:element[not(parent::rng:define)]" mode="step4.19">
	<ref name="{local:constructDefineName(.)}"/>
</xsl:template>
  
<xsl:template match="rng:define[not(rng:element)]" mode="step4.19"/>

<xsl:template match="rng:ref[@name=/*/rng:define[not(rng:element)]/@name]" mode="step4.19">
	<xsl:apply-templates select="/*/rng:define[string(@name)=string(current()/@name)]/*" mode="step4.19"/>
</xsl:template>

<!-- 4.21. empty element -->

<xsl:template match="/" mode="step4.21">
	<xsl:param name="out" select="true()" as="xs:boolean"/>
	<xsl:param name="stop-after" select="''"/>
	<xsl:comment>4.21. empty element</xsl:comment>
	<xsl:variable name="step" as="node()*">
		<xsl:document><xsl:apply-templates mode="step4.21"/></xsl:document>
	</xsl:variable>
	<xsl:if test="$out">
		<xsl:result-document href="{$out-name}4-21.rng" format="intermediate-result">
			<xsl:sequence select="$step"/>
		</xsl:result-document>
	</xsl:if>
  <!-- 4.21 is the last step -->
  <xsl:sequence select="$step"/>
</xsl:template>

<xsl:template match="*" mode="step4.21" priority="-1">
	<xsl:param name="updated" select="false()" as="xs:boolean"/>
	<xsl:copy>
		<xsl:if test="$updated">
			<xsl:attribute name="updated" select="$updated"/>
		</xsl:if>
		<xsl:apply-templates select="@*, node()" mode="step4.21"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="text()|@*" mode="step4.21" priority="-1">
  <xsl:sequence select="."/>
</xsl:template>

<xsl:template match="@updated" mode="step4.21"/>

<xsl:template match="/rng:grammar" mode="step4.21">
  <xsl:message> + [DEBUG] step4.21: <xsl:sequence select="name(.)"/></xsl:message>
	<xsl:variable name="thisIteration" as="node()*">
	  <xsl:document>
  		<xsl:copy>
  			<xsl:apply-templates select="@*, node()" mode="step4.21"/>
  		</xsl:copy>
	  </xsl:document>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$thisIteration//@updated">
			<xsl:apply-templates select="$thisIteration/rng:grammar" mode="step4.21"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="$thisIteration"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="rng:choice[*[1][not(self::rng:empty)] and *[2][self::rng:empty]]" mode="step4.21" priority="10">
	<xsl:copy>
		<xsl:attribute name="updated" select="'1'"/>
		<xsl:apply-templates select="*[2], *[1]" mode="step4.21" />
	</xsl:copy>
</xsl:template>

<xsl:template match="rng:group[count(rng:empty)=1]|rng:interleave[count(rng:empty)=1]" mode="step4.21" priority="10">
	<xsl:apply-templates select="*[not(self::rng:empty)]" mode="step4.21">
		<xsl:with-param name="updated" select="true()" as="xs:boolean"/>
	</xsl:apply-templates>
</xsl:template>

<xsl:template mode="step4.21" 
  match="  
  rng:group[count(rng:empty)=2]|
  rng:interleave[count(rng:empty)=2]|
  rng:choice[count(rng:empty)=2]|
  rng:oneOrMore[rng:empty]" 
  >
	<rng:empty updated="1"/>
</xsl:template>

  <xsl:function name="local:constructDefineName" as="xs:string">
    <xsl:param name="context" as="element(rng:element)"/>
    <xsl:variable name="result" as="xs:string"
      select="concat('__', string($context/rng:name), '-elt-', generate-id($context))"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>



</xsl:stylesheet>
