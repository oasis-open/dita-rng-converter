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
  <!-- =====================================================================
       Generates DTD .mod files for modules (as opposed to document type shells).
       
       The initial mode is "moduleFile", applied to the RNG file for a
       given module.
       
       Note that generation of .ent files is done in mode "entityFile",
       implemented in rng2ditaent.xsl
       ===================================================================== -->
  
  <xsl:include href="mode-modulefile.xsl"/>
  <xsl:include href="mode-element-decls.xsl"/>
  <xsl:include href="mode-generate-parment-decl-from-define.xsl"/>
  <xsl:include href="mode-generate-attlist-decl.xsl"/>
  <xsl:include href="mode-element-name-entities.xsl"/>
  <xsl:include href="mode-external-ref.xsl"/>
  <xsl:include href="mode-make-element-type-name-parments.xsl"/>
  <xsl:include href="mode-class-att-decls.xsl"/>
  <xsl:include href="mode-header-comment.xsl"/>
  <xsl:include href="mode-generate-referenced-parameter-entities.xsl"/>
  <xsl:include href="mode-construct-effective-pattern.xsl"/>
  
</xsl:stylesheet>