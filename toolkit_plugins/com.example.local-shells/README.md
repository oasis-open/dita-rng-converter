# Sample Local Shells

This project provides sample local document type shells you can use as
the starting point for your own local shells.

These shells use just the standard DITA TC-defined topic types and domains,
so as a starting point they exactly match the TC-provided shells.

These shells are are packaged as a DITA Open Toolkit plug-in for convenience
in using and deploying these shells in Open Toolkit-based environments (i.e.,
OxygenXML, Open Toolkit itself, any XML processor that can use the XML catalog
managed by Open Toolkit).

## Making your own local shells

The following steps reflect use of DITA Open Toolkit to add your local shells to the master entity resolution catalog managed by Open Toolkit (`plugins/org.dita.base/catalog-dita.xml`). 
If you are using OxygenXML to test the shells, you can test with the Open Toolkit that comes with Oxygen's DITA framework or set up a new Open Toolkit installation and test with that, setting the Open Toolkit as a custom Toolkit in Oxygen's DITA preferences. These instructions reflect Open Toolkit 3.6 but should work with older versions by adjusting the mechanism for installing the new plug-in (i.e., `dita --install` or `ant -f integrator.xml`).

To make your own working shells from these samples, perform the following steps:

1. Copy the `com.example.local-shells` directory to an appropriate work area and give it a name that reflects your ownership of the document type shells (i.e., "com.contrext.doctypes").
1. Edit the `catalog.xml` files under the `rng` and `dtd` directories and change `com.example.doctypes` to the appropriate identifier for your ownership, i.e., `com.contrext.doctypes`.
1. Edit the `.ditamap` and `.dita` files in the `templates/` directory and change the value `com.example.doctypes` to the same value you used in step 2 (i.e., `com.contrext.doctypes`).
1. Deploy your new plugin to a DITA Open Toolkit by copying the directory you created in Step 1 to the Toolkit's `plugins/` directory and then running the `dita install` command.
1. Edit one or more of the templates modified in Step 3 and see if they validate.
