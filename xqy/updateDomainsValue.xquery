(: XQuery module to update the @domains value in 
   DITA document type shells based on the contributions
   from all included modules.
 :)
declare namespace rng="http://relaxng.org/ns/structure/1.0";
declare namespace dita="http://dita.oasis-open.org/architecture/2005/";
declare namespace a="http://relaxng.org/ns/compatibility/annotations/1.0";

declare function local:getDomainsContributions($e as element()) as xs:string* {
   
    let $contribs := for $import in $e//rng:include
        return local:getDomainsContribution($import)
    for $contrib in $contribs order by $contrib
        return $contrib
};

declare function local:getDomainsContribution($import as element(rng:include)) as xs:string* {
    let $refUri := resolve-uri($import/@href, base-uri(root($import)))
    let $doc := doc($refUri)
    let $contribs := (string($doc//dita:domainsContribution), local:getDomainsContributions($doc/*)) 
    return if (normalize-space(string-join($contribs, '')) = '')
              then ()
              else $contribs   
};

declare updating function local:updateDomains($e as element(rng:grammar)) {
(: The newline character will be literally "&#xA;" in the updated value,
   with sufficients spaces after it to indent each entry under the first one :)
   let $domains := string-join(local:getDomainsContributions($e), 
                               '&#xA;                         ')
   let $domainsDecl := $e//rng:attribute[@name = 'domains']/@a:defaultValue
   return replace value of node $domainsDecl with $domains
   
};

let $doc := doc(document-uri(.))

return local:updateDomains($doc/*)

