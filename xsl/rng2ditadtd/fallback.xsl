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
  exclude-result-prefixes="xs xd rng rnga relpath str ditaarch rngfunc local rng2ditadtd"
  expand-text="yes"
  version="3.0"
  >
  
  <!-- Lowest-priority templates that act as fallbacks. -->

  <xsl:template match="text()" priority="-1"
    mode="#all"
  />
  
  <xsl:template match="rng:div" mode="#all">
    <!-- RNG div elements are "transparent" and have no special meaning
         for DTD output (except possibly in a few special cases) 
         
         Note that this is really here for safety since we filter out
         all the divs before doing any output processing once we have
         gathered the modules to be processed.
      -->
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
  
</xsl:stylesheet>