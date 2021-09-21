<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================= -->
<!-- Sample map specialization                                     -->
<!-- Adds required "pubroot" topicref.                             -->
<!-- ============================================================= -->

<!-- ============================================================= -->
<!--                   ELEMENT NAME ENTITIES                       -->
<!-- ============================================================= -->

<!ENTITY % mymap       "mymap"                                       >
<!ENTITY % pubroot     "pubroot"                                     >
<!ENTITY % pubresources
                       "pubresources"                                >

<!-- ============================================================= -->
<!--                    ELEMENT DECLARATIONS                       -->
<!-- ============================================================= -->

<!--                    LONG NAME: My Map Type                     -->
<!ENTITY % mymap.content
                       "((%title;)?,
                         (%topicmeta;)?,
                         (%pubresources;)*,
                         (%pubroot;),
                         (%topicref;)*,
                         (%reltable;)*)"
>
<!ENTITY % mymap.attributes
              "title
                          CDATA
                                    #IMPLIED

               id
                          ID
                                    #IMPLIED

               %conref-atts;
               anchorref
                          CDATA
                                    #IMPLIED

               outputclass
                          CDATA
                                    #IMPLIED

               %localization-atts;
               %topicref-atts;
               %select-atts;"
>
<!ELEMENT  mymap %mymap.content;>
<!ATTLIST  mymap %mymap.attributes;
                 %arch-atts;
                 domains 
                        CDATA
                                  "&included-domains;"
>


<!--                    LONG NAME: Publication Root                -->
<!ENTITY % pubroot.content
                       "((%topicmeta;)?,
                         (%data.elements.incl;)*,
                         (%topicref;)*)"
>
<!ENTITY % pubroot.attributes
              "href
                          CDATA
                                    #IMPLIED

               keyref
                          CDATA
                                    #IMPLIED

               keys
                          CDATA
                                    #IMPLIED

               cascade
                          CDATA
                                    #IMPLIED

               format
                          CDATA
                                    'ditamap'

               outputclass
                          CDATA
                                    #IMPLIED

               %univ-atts;"
>
<!ELEMENT  pubroot %pubroot.content;>
<!ATTLIST  pubroot %pubroot.attributes;>


<!--                    LONG NAME: Publication Resources           -->
<!ENTITY % pubresources.content
                       "((%data.elements.incl;)*,
                         (%topicref;)*)"
>
<!ENTITY % pubresources.attributes
              "processing-role
                          CDATA
                                    'resource-only'

               cascade
                          CDATA
                                    #IMPLIED

               outputclass
                          CDATA
                                    #IMPLIED

               %univ-atts;"
>
<!ELEMENT  pubresources %pubresources.content;>
<!ATTLIST  pubresources %pubresources.attributes;>



<!-- ============================================================= -->
<!--             SPECIALIZATION ATTRIBUTE DECLARATIONS             -->
<!-- ============================================================= -->
  
<!ATTLIST  mymap        %global-atts;  class CDATA "- map/map mymap/mymap ">
<!ATTLIST  pubroot      %global-atts;  class CDATA "- map/topicref mymap/pubroot ">
<!ATTLIST  pubresources %global-atts;  class CDATA "- map/topicref mymap/pubresources ">

<!-- ================== End of My Map Type ==================== -->
 