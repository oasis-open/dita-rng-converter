<?xml version="1.0" encoding="UTF-8"?>
<!-- =============================================================  -->
<!-- Sample specialization module                                  -->
<!-- This module defines several specializations of the            -->
<!-- "markupname" element from the DITA 1.3 markup name            -->
<!-- domain, which is the base domain for the DITA 1.3             -->
<!-- XML domain.                                                   -->
<!-- =============================================================       -->
<!--                                                               -->

<!-- ============================================================= -->
<!--                   ELEMENT NAME ENTITIES                       -->
<!-- ============================================================= -->

<!ENTITY % rngpattern  "rngpattern"                                  >

<!-- ============================================================= -->
<!--                    ELEMENT DECLARATIONS                       -->
<!-- ============================================================= -->

<!--                    LONG NAME: RELAX NG pattern name           -->
<!ENTITY % rngpattern.content
                       "(#PCDATA |
                         %draft-comment; |
                         %required-cleanup; |
                         %text;)*"
>
<!ENTITY % rngpattern.attributes
              "%univ-atts;
               outputclass
                          CDATA
                                    #IMPLIED"
>
<!ELEMENT  rngpattern %rngpattern.content;>
<!ATTLIST  rngpattern %rngpattern.attributes;>



<!-- ============================================================= -->
<!--             SPECIALIZATION ATTRIBUTE DECLARATIONS             -->
<!-- ============================================================= -->
  
<!ATTLIST  rngpattern   %global-atts;  class CDATA "+ topic/keyword markup-d/markupname mymention-d/rngpattern ">

<!-- ================== End of DITA XML Construct Domain ==================== -->
 