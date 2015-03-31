<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <ns uri="http://relaxng.org/ns/structure/1.0" prefix="rng"/>
  <ns uri="http://relaxng.org/ns/compatibility/annotations/1.0" prefix="a"/>
  <ns uri="http://dita.oasis-open.org/architecture/2005/" prefix="dita"/>
  
  <let name="domains" value="/rng:grammar/rng:div/rng:define[@name='domains-att']/rng:optional/rng:attribute[@name='domains']/@a:defaultValue"/>
  
  <pattern id="checkDomainsDefault">
    <rule context="rng:grammar">
      <assert test="rng:div/rng:define[@name='domains-att']">
        The domains-att pattern should de defined.
      </assert>            
    </rule>
    <rule context="rng:div/rng:define[@name='domains-att']">
      <assert test="$domains!=''">
        The domains-att pattern should define an optional domains attribute with a default value.
      </assert>            
    </rule>
  </pattern>
  
  <pattern id="checkIncludedDomains">
    <rule context="rng:include">
      <assert test="document(@href)/rng:grammar/dita:moduleDesc/dita:moduleMetadata/dita:domainsContribution">
        The domain module should define a domains attribute contribution by specifying the 
        'domainContribution' element in a moduleDesc/moduleMetadata annotation.
      </assert>
      
      <assert test="min(document(@href)/rng:grammar/dita:moduleDesc/dita:moduleMetadata/dita:domainsContribution/contains($domains, .))">
        The domain values defined in an included domain file should be present in the domains attribute default value.
      </assert>            
    </rule>        
  </pattern>
</schema>