#!/bin/bash
set -e

source .env

BASE_DN="o=$ORG"
ADMIN_DN="cn=$ADMIN_CN,$BASE_DN"

LDIF=$(mktemp)
trap "rm -f $LDIF" EXIT

cat > $LDIF <<EOF
dn: cn=test_group,$BASE_DN
changetype: add
objectClass: groupOfNames
objectClass: Top
cn: test_group
description: Test Group
member: $ADMIN_DN

dn: cn=test_user,$BASE_DN
changetype: add
objectClass: inetOrgPerson
objectClass: Top
cn: test_user
sn: User
givenName: Test
uid: test_user
userPassword: TestPass123

dn: cn=test_group,$BASE_DN
changetype: modify
add: member
member: cn=test_user,$BASE_DN
EOF

echo "Creating test user and group..."
ldapmodify -H ldaps://localhost:636 \
    -x -D "$ADMIN_DN" \
    -w "$ADMIN_PASSWORD" \
    -o tls_reqcert=never \
    -f $LDIF

echo "Verifying creation..."
ldapsearch -H ldaps://localhost:636 \
    -x -D "$ADMIN_DN" \
    -w "$ADMIN_PASSWORD" \
    -b "cn=test_group,$BASE_DN" \
    -o tls_reqcert=never \
    -LLL

echo "Test successful!"
