#!/bin/bash
#
# chg_pom_version.sh
#
# This script iterates on all pom.xml files under the current directory 
# recursively and changes the POM version using a four numbers format:  
# major.minor.buildnumber.changeset
#
# Major and minor are extracted from each POM, if minor is missing a 0 value is
# used. Buildnumber and changeset are obtained from the command line options.
#
# Any parent project reference in the POM is updated as well, but only if the 
# corresponding parent POM is found under any directory. 
#
# PARAMETERS
#   param $1: the build number
#   param $2: the changeset number
#
# EXAMPLE:
#   $ cd parent
#   $ ls
#   src/
#   child/
#   pom.xml
#   $ chg_pom_version.sh 20121231 123
#
# REQUIREMENTS
#   - xsltproc binary installed
#   - serveral XSLs for working on pom.xml files, they must be located in the 
#   same directory of this script: 
#     chpver.xsl  : changes the project parent version
#     chver.xsl   : changes the project version
#     coord.xsl   : gets the project coordinates, groupId:artifactId
#     pcoord.xsl  : gets the project parnet coordinates, groupId:artifactId
#     pver.xsl    : gets the project parent version
#     ver.xsl     : gets the project version
#
# AUTHOR
#   Written by Eduardo Lago Aguilar <eduardo.lago.aguilar@gmail.com> 
#

# Resolve script location, $_me may be a symbolic link
_me="${BASH_SOURCE[0]}"
script="$_me"
while [ -h "$script" ] ; do
  lst=$(ls -ld "$script")
  lnk=$(expr "$lst" : '.*-> \(.*\)$')
  if expr "$lnk" : '/.*' > /dev/null; then
    script="$lnk"
  else
    script=$(dirname "$script")/"$lnk"
  fi
done
_BIN=$(dirname "$script")

#############################
## POM XSL transformations ##
#############################

# Gets the project version using the pom.xml in the current directory or the 
# supplied pom.xml path
#
# param $1: (optional) the pom.xml to process, defaults to <current 
#   directory>/pom.xml
#
# Example:
#   $ ver
#   1.2.3
ver() {
  xsltproc $_BIN/ver.xsl - < ${1:-pom.xml}
}

# Changes the project version using the pom.xml in the current directory
#
# param $1: the new version to setup
#
# Example:
#   $ chver 4.5.6
chver() {
  local tmp_pom=$(mktemp)
  xsltproc --output ${tmp_pom} --stringparam version ${1?} $_BIN/chver.xsl - < pom.xml
  cat > pom.xml < ${tmp_pom}
  rm ${tmp_pom}
}

# Gets the project coordinate using the pom.xml in the current directory or the 
# supplied pom.xml path. The coordinate is formed from groupId and artifactId 
#
# param $1: (optional) the pom.xml to process, defaults to <current 
#   directory>/pom.xml
#
# Example:
#   $ coord
#   org.examples:demo-project
coord() {
  xsltproc $_BIN/coord.xsl - < ${1:-pom.xml}
}

# Gets the parent project version using the pom.xml in the current directory or 
# the supplied pom.xml path
#
# param $1: (optional) the pom.xml to process, defaults to <current 
#   directory>/pom.xml
#
# Example:
#   $ pver
#   1.2.3
pver() {
  xsltproc $_BIN/pver.xsl - < ${1:-pom.xml}
}

# Changes the parent project version using the pom.xml in the current directory
#
# param $1: the new parent version to set
#
# Example:
#   $ chpver 4.5.6
chpver() {
  local tmp_pom=$(mktemp).xml
  xsltproc --output ${tmp_pom} --stringparam parent_version ${1?} $_BIN/chpver.xsl - < pom.xml
  cat > pom.xml < ${tmp_pom}
  rm ${tmp_pom}
}

# Gets the parent project coordinate using the pom.xml in the current directory 
# or the supplied pom.xml path. The coordinate is formed from groupId and 
# artifactId 
#
# param $1: (optional) the pom.xml to process, defaults to <current 
#   directory>/pom.xml
#
# Example:
#   $ pcoord
#   org.examples:demo-parent-project
pcoord() {
  xsltproc $_BIN/pcoord.xsl - < ${1:-pom.xml}
}

########################
## Version processing ##
########################

# Trims snapshot from the version
#
# Example:
#   $ trim_snapshot <<< 1.2.3-SNAPSHOT
#   1.2.3
trim_snapshot() {
  sed 's/-SNAPSHOT//'
}

# Formats the version # including Build Number and Changeset
#
# param $1: Build Number
# param $2: Changeset 
#
# Example:
#   $ fmt_ver 20121231 1234 <<< 10.2.0
#    10.2.20121231.1234
fmt_ver() {
  local bn=${1?}
  local cs=${2?}
  awk -v FS=. -v OFS=. -v bn=${bn} -v cs=${cs} '{if(NF==1) $2=0; $3=bn; $4=cs; NF=4; print $0}'
}

####################
## POM iterations ##
####################

# Iterate over all directories containing pom.xml files
#
# Example:
#   $ pom_dirs
#   ./grandchild2
#   .
#   ./child4
#   ./child2
#   ./child2/grandchild
#   ./child3/child3child
#   ./child3
#   ./child1
pom_dirs() {
  pushd "${base}" &>/dev/null
  find -type f -name pom.xml | xargs -i dirname {}
  popd &>/dev/null
}

# Finds the parent pom.xml directory location based on the coordinate, an empty 
# value is returned if the parent pom.xml isn't found
#
# Example:
#   $ find_parent_dir org.demo:demo-parent-project
#   ./child2
#  
find_parent_dir() {
  local coord=${1?}
  pushd "${base}" &>/dev/null 
  pom_dirs | while read pom_dir; do
    if [ $coord == $(coord ${pom_dir}/pom.xml) ] ; then
      cat <<< ${pom_dir} ;
      popd &>/dev/null
      return ;
    fi
  done
  popd &>/dev/null
}

# Recursively changes pom.xml versions in ascending order. Marks processed 
# pom.xml by touching a file pom.xml.changed. Returns the new version.
#
# param $1: the current pom.xml directory
#
# Example:
#   $ rec_ver /child2
#   10.2.20121231.1234
rec_ver() {
  local pom_dir=${1?} # current pom.xml directory
  local bn=${2?} # build number
  local cs=${3?} # changeset   local ver=$(ver)
  pushd "${base}/${pom_dir}" >/dev/null
  local ver=$(ver)
  local pver=$(pver)
  if [ ! -e pom.xml.changed ]; then
    if [ -n ""${pver} ] ; then
      local pdir=$(find_parent_dir $(pcoord))
      if [ -n ""${pdir} ]; then
        pver=$(rec_ver ${pdir} ${bn} ${cs})
        chpver ${pver}
      fi
    fi
    if [ -n ""${ver} ] ; then
      ver=$(trim_snapshot <<< ${ver} | fmt_ver ${bn} ${cs})
      chver ${ver}
    fi
    touch pom.xml.changed
  fi
  cat <<< ${ver:-${pver}}
  popd >/dev/null
}

# Iterates all pom.xml and performs the recursive changes
#
# Example:
#   $ doit
doit() {
  pom_dirs | \
    while read pom_dir; do 
      rec_ver ${pom_dir} ${bn} ${cs} > /dev/null
    done
}

base=~+  # current directory
bn=${1?} # build number
cs=${2?} # changeset
doit
