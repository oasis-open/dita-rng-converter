# dita-rng-converter
DITA-specific RNG-to-DTD and -XSD conversion tools. Produce conforming DTDs and XSDs from RNG shells and modules.

This project is *not* a work product of the OASIS Open DITA Technical Committee. 

*NOTE*:  This project may be pulled into an OASIS open source repository affiliated with the DITA TC at some point in the future. If this happens, the project and its contents will continue to be available under substantially the same license terms as used here (Apache 2, the same as is used for the DITA Open Toolkit).

This project provides the following transforms from RNG grammars that follow the coding conventions used by the DITA Technical Committee for the TC-defined modules and shells:

* RNG-to-DTD: Generates conforming DTD-syntax document type shells and modules
* RNG-to-XSD: Generates conforming XSD-syntax document type shells and modules
* XML entity resolution catalog generator: Generates XML entity resolution catalogs for the RNG, DTD, and XSD modules processed or generated.

The transforms are implemented as XSLT transforms and run through an Ant script. See the project documentation for details.

The transforms can be run standalone or through an Open Toolkit plugin. The transforms have no dependency on the DITA Open Toolkit itself.

You can use these transforms to generate both DITA 1.2 and DITA 1.3 shells and modules: RNG versions of the DITA 1.2 shells and vocabulary are included in the project (as developed by the DITA Technical Committee).