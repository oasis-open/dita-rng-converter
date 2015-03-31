<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="xs xd"
  version="2.0">
  <!-- =====================================
       XSLT shell to enable plugin-provided
       extensions to the base TC-provided 
       RNG-to-DTD transform.
       ===================================== -->
  
  <xsl:import href="rng2ditadtd.xsl"/>
  

  <dita:extension id="xsl.transtype-rng2dtd" 
    behavior="org.dita.dost.platform.ImportXSLAction" 
    xmlns:dita="http://dita-ot.sourceforge.net"/>

  
</xsl:stylesheet>