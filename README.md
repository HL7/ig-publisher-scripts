# FHIR IG Publisher scripts
A repository of scripts used to launch the publisher, manage the local publishing environment and ensure both scripts and publisher are 'current'

## UpdatePublisher
the `_updatePublisher.bat` and `_updatePublisher.sh` scripts do the following:

1. Check if we're online 
  1. Actually the check is to see if the FHIR terminology server is up. If you know you're online and you get a message "we're offline", just try later or manually download the IG Publisher jar file.
1. **Checks if the IG Publisher jar is in the folder `input-cache`**, and asks whether to download or update it from its [permanent location](https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar)
  1. **Check if the publisher is in the folder `..`**. If there is no publisher jar in `input-cache` but there is such a jar in the parent of the current folder, the script considers that as the target destination of the jar. This is because some authors don't want to have a 100MB+ jar file for each implementationGuide, having to update all of those when there is a new release.
  1. 
1. **Update these scripts including itself**. 

If the argument `/f` is passed to the script, it skips all prompts and downloads the jar. This is used in automated updates and build processes.

## GenOnce
the `_genonce.bat` and `_genonce.sh` scripts 
1. Check if we're online (i.e. if tx.fhir.org is reachable)
2. Runs the publisher to build the IG from the current folder and exits when done.

## GenContinuous
the `_gencontinuous.bat` and `_gencontinuous.sh` scripts 
1. Check if we're online (i.e. if tx.fhir.org is reachable)
2. Runs the publisher to build the IG from the current folder and monitors for file changes, in which case it will build again, until the user exits.  

<br/>

> **Security note**  
These scripts are intended to download executables, and can easily trigger antivirus software; In addition, security settings on the machine or domain may block some of these actions. If you encounter such issues and you can't get around them, then you may: 
a) download the jar manually from its [permanent location](https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar) into the `input-cache` or parent folder, instead of using `updatePublisher`  
and/or  
b) run the command line yourself instead of using `genonce`:   
`input-cache\publisher.jar" -ig . `  
or  
`..\publisher.jar" -ig . `
