(: Queries for inspecting the DITA RELAX NG schemas :)

declare namespace a="http://relaxng.org/ns/compatibility/annotations/1.0";
declare namespace dita="http://dita.oasis-open.org/architecture/2005/";
declare namespace rng="http://relaxng.org/ns/structure/1.0";

declare namespace rngf="urn:functions:dita-rng";

declare function rngf:getElementDefinitionPattern($grammar, $tagname) as element(rng:define) {
   let $patternName := concat($tagname, '.element')
   let $define := $grammar//rng:define[@name = $patternName]
   return $define
};


(: Resolve a ref within the same grammar document. The reference
   is resolved recursively.

   Input is an rng:ref elements.
   
   Result is the elements referenced, as a sequence
:)
declare function rngf:resolveLocalRef($ref as element(rng:ref), $alreadyFound as node()*) as element()* {
       let $targetName := string($ref/@name)
       let $targets := root($ref)//rng:define[@name = $targetName] except ($alreadyFound)
       for $target in $targets
           return ($targets , 
                   for $subref in $target//rng:ref
                       return rngf:resolveLocalRef($subref, ($targets | $alreadyFound)))
};

(: Resolve refs within the same grammar document. The references
   are resolved recursively.

   Input is one or more rng:ref elements. 
:)
declare function rngf:resolveLocalRefs($refs as element(rng:ref)*) as element()* {
   for $ref in $refs
       return rngf:resolveLocalRef($ref, ())
};

declare function rngf:getModuleShortName($grammar as element(rng:grammar)) as xs:string {
   let $moduleDesc := $grammar/dita:moduleDesc
   let $moduleShortName as xs:string := string($moduleDesc/dita:moduleMetadata/dita:moduleShortName)
   return $moduleShortName
};

(: Given the rng:element declaration for an element type, get the @class attribute declaration.
:)
declare function rngf:getDITAClass($elementDecl as element(rng:element)) as xs:string {
   let $tagname := string($elementDecl/@name)
   let $defines := rngf:resolveLocalRefs($elementDecl/rng:ref[@name = concat($tagname, '.attlist')])
   let $classAtt := ($defines//rng:attribute[@name = 'class'])[1]
   let $classValue := $classAtt/@a:defaultValue
   return ($classValue, 'No @class value')[1]
};

declare function rngf:allowsAttribute($elementDecl as element(rng:element), $attname as xs:string) as xs:boolean {
   let $tagname := string($elementDecl/@name)
   let $defines := rngf:resolveLocalRefs($elementDecl/rng:ref[@name = concat($tagname, '.attlist')])
   let $attdecls := ($defines//rng:attribute[@name = $attname])
   
   return count($attdecls) gt 0
};

declare function rngf:getElementDeclarationSummary($element as element(rng:element)) as node()* {
  rngf:getElementDeclarationSummary($element, ())
};

declare function rngf:getElementDeclarationSummary($element as element(rng:element), $additionalAtts as attribute()*) as node()* {
   <element name="{$element/@name}" 
                     module="{tokenize(document-uri(root($element)), '/')[last()]}"
                     class="{rngf:getDITAClass($element)}"
   >{$additionalAtts}</element>
};

declare function rngf:elementDeclarationReport($grammars as element(rng:grammar)*) as node()* {
let $result :=
 <element-summary>{
 let $elements := for $grammar in $grammars return $grammar//rng:element[@name]
 let $moduleNames := for $grammar in $grammars return rngf:getModuleShortName($grammar) 
 return ( 
   attribute total-element-types {count($elements)},
   attribute modules {string-join($moduleNames, ' ')}, 
   <all-elements>{
     for $element in $elements order by lower-case($element/@name)
         return rngf:getElementDeclarationSummary($element)
   }</all-elements>,
   <elements-by-module>{
     for $grammar in $grammars order by rngf:getModuleShortName($grammar)
         return <module name="{rngf:getModuleShortName($grammar)}">{
                for $element in $grammar//rng:element order by lower-case($element/@name)
                        return rngf:getElementDeclarationSummary($element)
                     }</module>
   }</elements-by-module>
      )
 }</element-summary>
 
 return $result
};

let $grammars := collection('/db/apps/dita-test-01/doctypes/rng/')/rng:grammar[dita:moduleDesc and
                              not(matches(dita:moduleDesc/dita:moduleMetadata/dita:moduleType, 'shell'))]

let $grammar := $grammars[rngf:getModuleShortName(.) = 'sw-d']
let $element := ($grammar//rng:element)[1]
let $tagname := $element/@name
let $ignoredAtts := ('class', 'domains', 'dita:DITAArchVersion')
let $phraseTypes := for $element in $grammars//rng:element
        let $class := rngf:getDITAClass($element)
        return if (starts-with($class, '+') and contains($class, ' topic/ph '))
               then $element
               else ()

return <result>{(
(:
<base type="topic/ph">{
   for $element in $phraseTypes
        return rngf:getElementDeclarationSummary($element, (attribute allows-keyref{rngf:allowsAttribute($element, 'keyref')}))
}</base>, :)
<defaultedAttributes xmlns="http://relaxng.org/ns/structure/1.0" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0">{
   for $element in $grammars//rng:element
       let $defines := rngf:resolveLocalRefs($element//rng:ref[@name = concat($element/@name, '.attlist')])
       let $attdecls := ($element, $defines//rng:attribute[not(string(@name) = $ignoredAtts)][@a:defaultValue != ''])
       return if (count($attdecls) gt 1)
                 then <element name="{$element/@name}">{$attdecls[position() gt 1]}</element>
                 else ''
       
       
  
}</defaultedAttributes>,
(: rngf:elementDeclarationReport($grammars), :)
''
)
}</result>

                              

