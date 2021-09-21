<!DOCTYPE html>
<html>
  <head>
    <title>OASIS TC Open Repository: dita-rng-converter</title>
  </head>
  <body>
<div>
<h1>README</h1>

<div>
<h2><a id="readme-general">OASIS TC Open Repository: dita-rng-converter</a></h2>

<p>This GitHub public repository ( <a href="https://github.com/oasis-open/dita-rng-converter">https://github.com/oasis-open/dita-rng-converter</a> ) was created at the request of the <a href="https://www.oasis-open.org/committees/dita/">OASIS Darwin Information Typing Architecture (DITA) TC</a> as an <a href="https://www.oasis-open.org/resources/open-repositories/">OASIS TC Open Repository</a> to support development of open source resources related to Technical Committee work.</p>

<p>While this TC Open Repository remains associated with the sponsor TC, its development priorities, leadership, intellectual property terms, participation rules, and other matters of governance are <a href="https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#governance-distinct-from-oasis-tc-process">separate and distinct</a> from the OASIS TC Process and related policies.</p>

<p>All contributions made to this TC Open Repository are subject to open source license terms expressed in the <a href="https://www.oasis-open.org/sites/www.oasis-open.org/files/Apache-LICENSE-2.0.txt">Apache License v 2.0</a>.  That license was selected as the declared <a href="https://www.oasis-open.org/resources/open-repositories/licenses">"Applicable License"</a> when the TC Open Repository was created.</p>

<p>As documented in <a href="https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#public-participation-invited">"Public Participation Invited"</a>, contributions to this OASIS TC Open Repository are invited from all parties, whether affiliated with OASIS or not.  Participants must have a GitHub account, but no fees or OASIS membership obligations are required.  Participation is expected to be consistent with the <a href="https://www.oasis-open.org/policies-guidelines/open-repositories">OASIS TC Open Repository Guidelines and Procedures</a>, the open source <a href="https://github.com/oasis-open/dita-rng-converter/blob/master/LICENSE">LICENSE</a> designated for this particular repository, and the requirement for an <a href="https://www.oasis-open.org/resources/open-repositories/cla/individual-cla">Individual Contributor License Agreement</a> that governs intellectual property.</p>

</div>

<div>
<h2><a id="purposeStatement">Statement of Purpose</a></h2>

<p>Statement of Purpose for this OASIS TC Open Repository (dita-rng-converter) as <a href="https://lists.oasis-open.org/archives/dita/201601/msg00040.html">proposed</a> and <a href="https://www.oasis-open.org/committees/download.php/57596/minutes20160223.txt">approved</a> by the TC:</p>

<p>The repository manages the source code and supporting documentation for the RELAX NG-to-DTD and
          RELAX NG-to-XSD (and any other RNG-to-X transforms that might be developed, such as RELAX
          NG-to-EDD or RELAX NG-to-Schematron) transforms developed originally for use by the DITA
          TC in producing the <a href="http://docs.oasis-open.org/dita/dita/v1.3/">DITA 1.3</a> and
          DITA 2.x DTDs and XSDs from the normative RELAX NG versions of the DITA 1.3 and DITA 2.x
          grammars. The converter is intended to make it easy for any DITA user to develop and
          maintain their own document type shells, constraint modules, and vocabulary modules using
          RELAX NG, which has proven to be much easier to use than DTD or XSD.</p>

</div>

<div><h2><a id="purposeClarifications">Additions to Statement of Purpose</a></h2>

<div><h3>Tool Overview</h3>
<p>
This project provides the following transforms from RNG grammars that follow the coding conventions used by the DITA Technical Committee for the TC-defined modules and shells:
</p><ul>
<li>RNG-to-DTD: Generates both DTD-syntax document type shells and modules as well as single-file
              ("monolithic") DTDs.</li>
<li>RNG-to-XSD: Generates both modular (DITA 1.x-style) XSD-syntax document type shells and modules
              that use the XSD redefine feature (within limits on the ability to generate modular
              constrained XSDs) as well as "monolithic" single-file XSDs that do not use
              redefine.</li>
<li>XML entity resolution catalog generator: Generates XML entity resolution catalogs for the RNG, DTD, and XSD modules processed or generated.</li>
</ul>
<p>The transforms are implemented as XSLT transforms and run through an Ant script. See the project documentation for details.</p>
<p>The transforms can be run standalone or through an Open Toolkit plug-in. The transforms have no
            dependency on DITA Open Toolkit itself.</p>
<p>You can use these transforms to generate shells and modules for all DITA versions through
            2.0.</p>
<p><b>NOTE:</b> At some point the OASIS-defined grammars will be removed from this project and you'll need to get the latest DITA Open Toolkit 
distribution in order to minimize the number of copies of the OASIS-provided grammars.</p>
</div>
<div><h3>Development Plan</h3>

<p>The code as added 24 March 2016 is still under development and requires more work to make it
ready for general use. The latest code is on the develop branch.</p>
<p>The current development plan is:
</p><ol>
<li>Fix bugs related to infinite looping of code when generating shells, as reported by 
Toshihiko Makita on the DITA Community version of the repo (https://github.com/dita-community/dita-rng-converter/issues/2)</li>
<li>Refine the Ant scripts to ensure that all parameters are appropriate and working.</li>
<li>Finish documentation.</li> 
</ol>
<p>Schedule: Goal is to complete these actions by the end of December 2016 or as early in 2017 as possible.</p>
<p>Additional implementation goals include:
</p><ul>
<li>Provide a simple interactive tool for creating new document type shells and generating DTD and XSD from them.</li>
<li>Implement a FrameMaker EDD generation process to make it easier to use local shells, specializations, and 
constraints with FrameMaker.</li>
</ul>
<p>Please use the project issue tracker to report any bugs or log feature requests.</p>
<p>Please use the project Wiki for general discussion not related to specific bugs or features.</p>
</div><!-- Dev plan -->

</div>

<div>
<h2><a id="maintainers">Maintainers</a></h2>

<p>TC Open Repository <a href="https://www.oasis-open.org/resources/open-repositories/maintainers-guide">Maintainers</a> are responsible for oversight of this project's community development activities, including evaluation of GitHub <a href="https://github.com/oasis-open/dita-rng-converter/blob/master/CONTRIBUTING.md#fork-and-pull-collaboration-model">pull requests</a> and <a href="https://www.oasis-open.org/policies-guidelines/open-repositories#repositoryManagement">preserving</a> open source principles of openness and fairness. Maintainers are recognized and trusted experts who serve to implement community goals and consensus design preferences.</p>

<p>Initially, the associated TC members have designated one or more persons to serve as Maintainer; subsequently, participating community members may select additional or substitute Maintainers, per consensus agreements.</p>

<p><b><a id="currentMaintainers">Current Maintainers of this TC Open Repository</a></b></p>

<ul>
<li><a href="mailto:ekimber@contrext.com">Eliot Kimber</a> (<code>ekimber@contrext.com</code>); GitHub ID: <a href="https://github.com/drmacro">drmacro</a>; OASIS Individual Member</li>
</ul>
</div>

<div><h2><a id="aboutOpenRepos">About OASIS TC Open Repositories</a></h2>

<p><ul>
<li><a href="https://www.oasis-open.org/resources/open-repositories/">TC Open Repositories: Overview and Resources</a></li>
<li><a href="https://www.oasis-open.org/resources/open-repositories/faq">Frequently Asked Questions</a></li>
<li><a href="https://www.oasis-open.org/resources/open-repositories/licenses">Open Source Licenses</a></li>
<li><a href="https://www.oasis-open.org/resources/open-repositories/cla">Contributor License Agreements (CLAs)</a></li>
<li><a href="https://www.oasis-open.org/resources/open-repositories/maintainers-guide">Maintainers' Guidelines and Agreement</a></li>
</ul></p>

</div>

<div><h2><a id="feedback">Feedback</a></h2>

<p>Questions or comments about this TC Open Repository's activities should be composed as GitHub issues or comments. If use of an issue/comment is not possible or appropriate, questions may be directed by email to the Maintainer(s) <a href="#currentMaintainers">listed above</a>.  Please send general questions about TC Open Repository participation to OASIS Staff at <a href="mailto:repository-admin@oasis-open.org">repository-admin@oasis-open.org</a> and any specific CLA-related questions to <a href="mailto:repository-cla@oasis-open.org">repository-cla@oasis-open.org</a>.</p>

</div></div>
  </body></html>