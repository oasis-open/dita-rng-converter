## OASIS TC Open Repository: dita-rng-converter

This GitHub public repository ( [https://github.com/oasis-open/dita-rng-converter](https://github.com/oasis-open/dita-rng-converter) ) was created at the request of the [OASIS Darwin Information Typing Architecture (DITA) TC](https://www.oasis-open.org/committees/dita/) as an [OASIS TC Open Repository](https://www.oasis-open.org/resources/open-repositories/) to support development of open source resources related to Technical Committee work.

While this TC Open Repository remains associated with the sponsor TC, its development priorities, leadership, intellectual property terms, participation rules, and other matters of governance are [separate and distinct](https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#governance-distinct-from-oasis-tc-process) from the OASIS TC Process and related policies.

All contributions made to this TC Open Repository are subject to open source license terms expressed in the [Apache License v 2.0](https://www.oasis-open.org/sites/www.oasis-open.org/files/Apache-LICENSE-2.0.txt). That license was selected as the declared ["Applicable License"](https://www.oasis-open.org/resources/open-repositories/licenses) when the TC Open Repository was created.

As documented in ["Public Participation Invited"](https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#public-participation-invited), contributions to this OASIS TC Open Repository are invited from all parties, whether affiliated with OASIS or not. Participants must have a GitHub account, but no fees or OASIS membership obligations are required. Participation is expected to be consistent with the [OASIS TC Open Repository Guidelines and Procedures](https://www.oasis-open.org/policies-guidelines/open-repositories), the open source [LICENSE](https://github.com/oasis-open/dita-rng-converter/blob/master/LICENSE) designated for this particular repository, and the requirement for an [Individual Contributor License Agreement](https://www.oasis-open.org/resources/open-repositories/cla/individual-cla) that governs intellectual property.

## Statement of Purpose

Statement of Purpose for this OASIS TC Open Repository (dita-rng-converter) as [proposed](https://lists.oasis-open.org/archives/dita/201601/msg00040.html) and [approved](https://www.oasis-open.org/committees/download.php/57596/minutes20160223.txt) by the TC:

The repository manages the source code and supporting documentation for the RELAX NG-to-DTD and RELAX NG-to-XSD (and any other RNG-to-X transforms that might be developed, such as RELAX NG-to-EDD or RELAX NG-to-Schematron) transforms developed originally for use by the DITA TC in producing the [DITA 1.3](http://docs.oasis-open.org/dita/dita/v1.3/) and DITA 2.x DTDs and XSDs from the normative RELAX NG versions of the DITA 1.3 and DITA 2.x grammars. The converter is intended to make it easy for any DITA user to develop and maintain their own document type shells, constraint modules, and vocabulary modules using RELAX NG, which has proven to be much easier to use than DTD or XSD.

### Tool Overview

This project provides the following transforms from RNG grammars that follow the coding conventions used by the DITA Technical Committee for the TC-defined modules and shells:

*   RNG-to-DTD: Generates both DTD-syntax document type shells and modules as well as single-file ("monolithic") DTDs.
*   RNG-to-XSD: Generates both modular (DITA 1.x-style) XSD-syntax document type shells and modules that use the XSD redefine feature (within limits on the ability to generate modular constrained XSDs) as well as "monolithic" single-file XSDs that do not use redefine.
*   XML entity resolution catalog generator: Generates XML entity resolution catalogs for the RNG, DTD, and XSD modules processed or generated.

The transforms are implemented as XSLT transforms and run through an Ant script. See the project documentation for details.

The transforms can be run standalone or through an Open Toolkit plug-in. The transforms have no dependency on DITA Open Toolkit itself.

You can use these transforms to generate shells and modules for all DITA versions through 2.0.

**NOTE:** At some point the OASIS-defined grammars will be removed from this project and you'll need to get the latest DITA Open Toolkit distribution in order to minimize the number of copies of the OASIS-provided grammars.

### Development Plan

The code as added 24 March 2016 is still under development and requires more work to make it ready for general use. The latest code is on the develop branch.

The current development plan is:

1.  Fix bugs related to infinite looping of code when generating shells, as reported by Toshihiko Makita on the DITA Community version of the repo (https://github.com/dita-community/dita-rng-converter/issues/2)
2.  Refine the Ant scripts to ensure that all parameters are appropriate and working.
3.  Finish documentation.

Schedule: Goal is to complete these actions by the end of April 2022.

Additional implementation goals include:

*   Provide a simple interactive tool for creating new document type shells and generating DTD and XSD from them.
*   Implement a FrameMaker EDD generation process to make it easier to use local shells, specializations, and constraints with FrameMaker.

Please use the project issue tracker to report any bugs or log feature requests.

Please use the project Wiki for general discussion not related to specific bugs or features.

## Maintainers

TC Open Repository [Maintainers](https://www.oasis-open.org/resources/open-repositories/maintainers-guide) are responsible for oversight of this project's community development activities, including evaluation of GitHub [pull requests](https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#fork-and-pull-collaboration-model) and [preserving](https://www.oasis-open.org/policies-guidelines/open-repositories#repositoryManagement) open source principles of openness and fairness. Maintainers are recognized and trusted experts who serve to implement community goals and consensus design preferences.

Initially, the associated TC members have designated one or more persons to serve as Maintainer; subsequently, participating community members may select additional or substitute Maintainers, per consensus agreements.

**Current Maintainers of this TC Open Repository**

*   [Eliot Kimber](mailto:ekimber@contrext.com) (`ekimber@contrext.com`); GitHub ID: [drmacro](https://github.com/drmacro); OASIS Individual Member

## About OASIS TC Open Repositories

*   [TC Open Repositories: Overview and Resources](https://www.oasis-open.org/resources/open-repositories/)
*   [Frequently Asked Questions](https://www.oasis-open.org/resources/open-repositories/faq)
*   [Open Source Licenses](https://www.oasis-open.org/resources/open-repositories/licenses)
*   [Contributor License Agreements (CLAs)](https://www.oasis-open.org/resources/open-repositories/cla)
*   [Maintainers' Guidelines and Agreement](https://www.oasis-open.org/resources/open-repositories/maintainers-guide)

## Feedback

Questions or comments about this TC Open Repository's activities should be composed as GitHub issues or comments. If use of an issue/comment is not possible or appropriate, questions may be directed by email to the Maintainer(s) [listed above](#currentMaintainers). Please send general questions about TC Open Repository participation to OASIS Staff at [repository-admin@oasis-open.org](mailto:repository-admin@oasis-open.org) and any specific CLA-related questions to [repository-cla@oasis-open.org](mailto:repository-cla@oasis-open.org).