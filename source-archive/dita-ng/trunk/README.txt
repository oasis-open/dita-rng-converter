*Step 1 - Add the plugin to your DITA OT installation*
****************************************************************
    You can download the latest DITA-NG distribution to get the Relax NG support
    as a DITA-OT plugin
        dita-ngVERSION.zip 
    or you can checkout the DITA-NG project then run
        ant clean
        ant
    The plugin will be packed as an archive in the dist subfolder
        dita-ngVERSION.zip
    (VERSION is the plugin version number using the YYYYMMDD format, YYYY=year, 
    MM=month and DD=day).

    Extract the archive in the plugins folder of your DITA-OT installation. 
    The result should be a org.dita-ng.doctypes folder inside your DITA-OT plugins folder.

*Step 2 - Integrate the plugin*
****************************************************************
    Change the startcmd.sh and startcmd.bat scripts to add the dita-ng.jar and jing.jar 
    in the classpath by adding them to NEW_CLASSPATH as the last instruction that sets 
    the NEW_CLASSPATH value. For example for startcms.sh the change will be:
        NEW_CLASSPATH="$DITA_DIR/plugins/org.dita-ng.doctypes/lib/dita-ng.jar:$DITA_DIR/plugins/org.dita-ng.doctypes/lib/jing.jar:$NEW_CLASSPATH"

    Make sure DITA_HOME is set. For example you can set that running in your actual DITA home folder: 
        export DITA_HOME=.
    Run the startcmd script
        ./startcmd.sh
    In the shell started by the previous command run:
        ant -f integrator.xml

*Step 3 - Check that everything works*
****************************************************************
    Run a transformation to make sure everything is working. 
    For example, to generate XHTML from the flowers sample use: 
        ant -f build.xml -Dargs.input=plugins/org.dita-ng.doctypes/demo/flowers/flowers.ditamap -Doutput.dir=plugins/org.dita-ng.doctypes/demo/flowers/out -Dtranstype=xhtml
    The result will be in plugins/org.dita-ng.doctypes/demo/flowers/out/index.html
    To generate PDF from the flowers sample use: 
        ant -f build.xml -Dargs.input=plugins/org.dita-ng.doctypes/demo/flowers/flowers.ditamap -Doutput.dir=plugins/org.dita-ng.doctypes/demo/flowers/out -Dtranstype=pdf
    The result will be in plugins/org.dita-ng.doctypes/demo/flowers/out/flowers.pdf
    