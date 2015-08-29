These document types are used by the RNG modules to govern the DITA-specific markup
embedded in the RNG modules or the RNG modules themselves.

The rngGrammar module defines the RNG markup as a DITA foreign vocabulary, allowing
you to literally include RNG markup in DITA topics.

The vocabularyModuleDesc grammar governs the DITA-specific markup required to make
the RNG modules work as the source for DTD and XSD generation. It is defined so
that the module description markup could be processed as a DITA topic (with the
caveat that it requires the use of namespaced elements, which DITA does not formally
allow). 