# Change POMs versions

This script iterates on all pom.xml files under the current directory 
recursively, and changes the POM version using a four numbers format:  
major.minor.buildnumber.changeset

Major and minor are extracted from each POM, if minor is missing a 0 value is
used. Buildnumber and changeset are obtained from the command line options.

Any parent project reference in the POM is updated as well, but only if the 
corresponding parent POM is found under any directory. 

## PARAMETERS
  
- param $1: the build number
- param $2: the changeset number

## EXAMPLE

```bash
$ cd parent
$ ls
src/
child/
pom.xml
$ chg_pom_version.sh 20121231 123
```

## REQUIREMENTS
- xsltproc binary installed

## INSTALL

- Copy `chg_pom_version.sh` and XSLs files to ~/bin
- Ensure that ~/bin is in the PATH environment variable by editing ~/.bashrc and appending export PATH=$PATH:~/bin


