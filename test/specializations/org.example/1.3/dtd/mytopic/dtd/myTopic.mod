<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================= -->
<!-- Sample topic specialization. Sets the root element to "myTopic". -->
<!-- ============================================================= -->

<!-- ============================================================= -->
<!--                   ELEMENT NAME ENTITIES                       -->
<!-- ============================================================= -->

<!ENTITY % mytopic     "mytopic"                                     >

<!-- ============================================================= -->
<!--                    ELEMENT DECLARATIONS                       -->
<!-- ============================================================= -->

<!ENTITY % mytopic-info-types
              "%info-types;,
"
>
<!--                    LONG NAME: myTopic                         -->
<!ENTITY % mytopic.content
                       "((%title;),
                         (%titlealts;,
)?,
                         (%abstract; |
                          %shortdesc;)?,
                         (%prolog;,
)?,
                         (%body;,
)?,
                         (%related-links;,
)?,
                         (%mytopic-info-types;,
)*,
)"
>
<!ENTITY % mytopic.attributes
              "id
                          ID
                                    #REQUIRED
               %conref-atts;
               %select-atts;
               %localization-atts;
               outputclass
                          CDATA
                                    #IMPLIED

"
>
<!ELEMENT  mytopic %mytopic.content;>
<!ATTLIST  mytopic %mytopic.attributes;
                 %arch-atts;
                 domains 
                        CDATA
                                  "&included-domains;"
>



<!-- ============================================================= -->
<!--             SPECIALIZATION ATTRIBUTE DECLARATIONS             -->
<!-- ============================================================= -->
  
<!ATTLIST  mytopic      %global-atts;  class CDATA "- topic/topic mytopic/mytopic ">

<!-- ================== End of DITA Concept ==================== -->
 