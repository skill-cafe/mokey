#!/bin/bash

# following must be the same as what's in the build script
ADMINPASS='Passwd-of-IPA-admin-user'
ADMINUSER='username-of-IPA-admin-user'

echo '=== Creating the folder for the keytab ==='
mkdir /etc/mokey/keytab

echo ''
echo '=== Installing the Kerberos client ==='
echo ''

ipa-client-install -U --domain tcc.local --server ipa.tcc.local --realm TCC.LOCAL -p $ADMINUSER -w "$ADMINPASS"

echo ''
echo 'Registering the mokey server with the domain'
echo ''

echo -n "$ADMINPASS" | kinit "$ADMINUSER"
ipa role-add 'Mokey User Manager' --desc='Mokey User management'
ipa role-add-privilege 'Mokey User Manager' --privilege='User Administrators'
ipa user-add mokeyapp --first Mokey --last App
ipa role-add-member 'Mokey User Manager' --users=mokeyapp
ipa-getkeytab -s ipa.tcc.local -p mokeyapp -k /etc/mokey/keytab/mokeyapp.keytab
chmod 640 /etc/mokey/keytab/mokeyapp.keytab
chgrp mokey /etc/mokey/keytab/mokeyapp.keytab

