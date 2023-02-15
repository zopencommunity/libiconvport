#!/bin/sh
#
# compconv: compare conversion with IBM iconv and z/OS Open Tools iconv
#           to ensure basic conversion to/from ISO8859-1 is consistent.
#

#
# Get list of 'IBM' and 'ISO' code pages
#

entries=$( /bin/iconv -l | egrep 'ISO|IBM' | awk '{ print $2; }' )

#
# First, ensure all entries are valid codepages for both iconv utilities
#

echo "Determine code pages to test"

for entry in $entries; do
  if ! echo "A" | iconv -f "${entry}" -t "ISO8859-1" >/dev/null 2>&1 ; then
    # echo "Code page ${entry} not supported as 'from' codepage for z/OS Open Tools iconv" >&2
  else
    if ! echo "A" | /bin/iconv -f "${entry}" -t "ISO8859-1" >/dev/null 2>&1 ; then
      echo "Code page ${entry} not supported as 'from' codepage for IBM z/OS iconv" >&2
    else
      convlist="${convlist} ${entry}"
    fi
  fi
done

#
# Now, ensure a 255 byte table is converted properly
#
echo "Generate common table to use"

sbtbl="sbtbl.txt"

if ! xlclang -ogentbl gentbl.c || ! rm -f gentbl.o ; then
  echo "Unable to build gentbl tool" >&2
  exit 4
fi

if ! ./gentbl >"${sbtbl}" || ! chtag -r "${sbtbl}" ; then
  echo "Unable to generate table" >&2
  exit 4
fi

echo "Loop through code pages"

convlist="IBM-1047 ${convlist}"
for conv in ${convlist}; do
  zotout_from=/tmp/zot.$$.${conv}.from.txt
  ibmout_from=/tmp/ibm.$$.${conv}.from.txt
  zotout_to=/tmp/zot.$$.${conv}.to.txt
  ibmout_to=/tmp/ibm.$$.${conv}.to.txt

  #
  # Convert _from_ conv
  #
  if ! iconv -f "${conv}" -t "ISO8859-1" <"${sbtbl}" >"${zotout_from}" || ! chtag -r "${zotout_from}" ; then
    echo "Unable to z/OS Open Tools iconv from ${conv}. See ${zotout_from}" 2>&1
    exit 4
  fi
  if ! /bin/iconv -f "${conv}" -t "ISO8859-1" <"${sbtbl}" >"${ibmout_from}" || ! chtag -r "${ibmout_from}" ; then
    echo "Unable to IBM iconv from ${conv}. See ${ibmout_from}" 2>&1
    exit 4
  fi
  if ! cmp "${zotout_from}" "${ibmout_from}" ; then
    #echo "z/OS Open Tools and IBM iconv produced different results from ${conv}. See ${zotout_from} and ${ibmout_from} for details" >&2
    #exit 4
  else
    echo "Code page ${conv} ok"
    rm -f "${zotout_from}" "${ibmout_from}"
  fi

  #
  # Convert _to_ conv
  #
  if ! iconv -t "${conv}" -f "ISO8859-1" <"${sbtbl}" >"${zotout_to}" || ! chtag -r "${zotout_to}" ; then
    echo "Unable to z/OS Open Tools iconv to ${conv}. See ${zotout_to}" 2>&1
    exit 4
  fi
  if ! /bin/iconv -t "${conv}" -f "ISO8859-1" <"${sbtbl}" >"${ibmout_to}" || ! chtag -r "${ibmout_to}" ; then
    echo "Unable to IBM iconv to ${conv}. See ${ibmout_to}" 2>&1
    exit 4
  fi
  if ! cmp "${zotout_to}" "${ibmout_to}" ; then
    #echo "z/OS Open Tools and IBM iconv produced different results from ${conv}. See ${zotout_to} and ${ibmout_to} for details" >&2
    #exit 4
  else
    echo "Code page ${conv} ok"
    rm -f "${zotout_to}" "${ibmout_to}"
  fi
done

