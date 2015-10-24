This directory contains all test-related
materials for testing the DITA document
types as produced by the OASIS TC.

Typical command line (OS X), run from the dita-rng-converter directory, with DITA-OT org.oasis-open.dita.v1_3 deployed (1.8 or 2.x):

ant -Drngsrc=/Users/ekimber/workspace-dita-community/dita-rng-converter/test/1.3/local-shells/rng/technicalContent/rng -Doutdir=/Users/ekimber/workspace-dita-community/dita-rng-converter/test/1.3/local-shells/dtd/ -DusePublicIDSInShell=true -DresultCatalogPath=$DITA_OT_OXY/catalog-dita.xml generate-dtd -l shell-generation.log
