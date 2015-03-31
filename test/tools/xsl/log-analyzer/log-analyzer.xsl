<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="xs xd"
  version="2.0">
  <!-- ==================================
       Analyzes the output of the Ant 
       DTD generation and document
       validation process to find errors
       and report success or failure.
       ================================== -->
  
  <xsl:param name="logfileUri" as="xs:string"/>
  <xsl:param name="failOnWarnings" as="xs:string" select="'false'"/>
  <xsl:param name="failOnWarningsBoolean" as="xs:boolean"
    select="matches($failOnWarnings, 'true|yes|1|on', 'i')"
  />
  
  <xsl:template name="processLog">
    <xsl:message> + [INFO] processLog: Processing log file "<xsl:value-of select="$logfileUri"/>"</xsl:message>
    
    <xsl:variable name="logdata" as="xs:string"
      select="unparsed-text($logfileUri)"
    />
    <xsl:variable name="lines" as="xs:string*"
      select="tokenize($logdata, '&#x0a;', 'm')"
    />

  <xsl:variable name="warningLines" as="xs:string*">
    <xsl:for-each select="$lines">
      <xsl:if test="matches(., '\[warn\]|\[warning\]|warn\s|warn!', 'i')">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
    
  <xsl:if test="count($warningLines) > 0">
    <xsl:message> - [WARN] Found warnings:</xsl:message>
    <xsl:for-each select="$warningLines">
      <xsl:message><xsl:sequence select="."/></xsl:message>
    </xsl:for-each>
  </xsl:if>  
   
  <xsl:variable name="errorLines" as="xs:string*">
    <xsl:for-each select="$lines">
      <xsl:if test="matches(., '\[ERROR\]|error\s|error!|not a valid XML document', 'i')">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
   
    
   <xsl:if test="count($errorLines) > 0">
      <xsl:message>Errors:
      <xsl:for-each select="$errorLines">
        <xsl:message><xsl:value-of select="."/></xsl:message>
      </xsl:for-each>    
      </xsl:message>
   </xsl:if>
    
  <xsl:if test="$failOnWarningsBoolean and count($warningLines) > 0">
    <xsl:if test="count($errorLines) > 0">
      <xsl:message terminate="yes"> -[FAIL] Found errors and warnings.</xsl:message>
    </xsl:if>
    <xsl:message terminate="yes"> -[FAIL] Found warnings and failOnWarnings is true</xsl:message>
  </xsl:if>  
    
  <xsl:if test="count($errorLines) > 0">
    <xsl:message terminate="yes"> -[FAIL] Found errors.</xsl:message>
  </xsl:if>  
    
  </xsl:template>
  
</xsl:stylesheet>