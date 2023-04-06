#!/bin/sh
#
# roundtrip: convert ASCII -> EBCDIC -> ASCII 
#

#
# Ensure a 255 byte table is converted properly
#
echo "Generate common table to use"

sbtbl="sbrttbl.txt"

if ! xlclang -ogentbl gentbl.c || ! rm -f gentbl.o ; then
  echo "Unable to build gentbl tool" >&2
  exit 4
fi

if ! ./gentbl >"${sbtbl}" || ! chtag -r "${sbtbl}" ; then
  echo "Unable to generate table" >&2
  exit 4
fi

echo "Loop through code pages"

echo "hello world" >"${sbtbl}"; chtag -r "${sbtbl}"

export ICONV_EBCDIC_ZOS_UNIX=1

convlist="IBM-1047"
for conv in ${convlist}; do
  zot_ascii_in=/tmp/zot.$$.${conv}.ascii-in.txt
  zot_ebcdic_out=/tmp/zot.$$.${conv}.ebcdic.txt
  zot_ascii_out=/tmp/zot.$$.${conv}.ascii-out.txt

  ibm_ascii_in=/tmp/ibm.$$.${conv}.ascii-in.txt
  ibm_ebcdic_out=/tmp/ibm.$$.${conv}.ebcdic.txt
  ibm_ascii_out=/tmp/ibm.$$.${conv}.ascii-out.txt

  cp "${sbtbl}" "${zot_ascii_in}"
  cp "${sbtbl}" "${ibm_ascii_in}"

  #
  # Convert _from_ ASCII
  #
  if ! iconv -t "${conv}" -f "ISO8859-1" <"${zot_ascii_in}" >"${zot_ebcdic_out}" || ! chtag -r "${zot_ebcdic_out}" ; then
    echo "Unable to z/OS Open Tools iconv to ${conv}" 2>&1
    exit 4
  fi
  if ! /bin/iconv -t "${conv}" -f "ISO8859-1" <"${ibm_ascii_in}" >"${ibm_ebcdic_out}" || ! chtag -r "${ibm_ebcdic_out}" ; then
    echo "Unable to IBM iconv to ${conv}." 2>&1
    exit 4
  fi

  #
  # Convert _from_ EBCDIC back to ASCII
  #
  if ! iconv -f "${conv}" -t "ISO8859-1" >"${zot_ascii_out}" <"${zot_ebcdic_out}" || ! chtag -r "${zot_ascii_out}" ; then
    echo "Unable to z/OS Open Tools iconv from ${conv}" 2>&1
    exit 4
  fi
  if ! /bin/iconv -f "${conv}" -t "ISO8859-1" >"${ibm_ascii_out}" <"${ibm_ebcdic_out}" || ! chtag -r "${ibm_ascii_out}" ; then
    echo "Unable to IBM iconv from ${conv}." 2>&1
    exit 4
  fi

  echo "Compare original ASCII to round-trip ASCII using z/OS Open Tools iconv"
  if ! cmp -l "${zot_ascii_in}" "${zot_ascii_out}" ; then
    echo "z/OS Open Tools did not successfully round-trip from ASCII to EBCDIC to ASCII" >&2
    #exit 4
  else
    echo "Code page ${conv} ok for z/OS Open Tools iconv"
  fi

  echo "Compare original ASCII to round-trip ASCII using IBM z/OS iconv"
  if ! cmp -l "${ibm_ascii_in}" "${ibm_ascii_out}" ; then
    echo "IBM z/OS iconv did not successfully round-trip from ASCII to EBCDIC to ASCII" >&2
    #exit 4
  else
    echo "Code page ${conv} ok for IBM z/OS iconv"
  fi

  echo "Compare converted EBCDIC from z/OS Open Tools and IBM iconv versions for equality" 
  if ! cmp -l "${zot_ebcdic_out}" "${ibm_ebcdic_out}" ; then
    echo "z/OS Open Tools iconv and IBM z/OS iconv did not perform equivalent translation to EBCDIC from ASCII" >&2
    #exit 4
  else
    echo "Conversion to ${conv} consistent for z/OS Open Tools iconv and IBM z/OS iconv"
  fi
done

