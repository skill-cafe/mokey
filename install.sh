#!/bin/bash

######################################################################
# Important: This file requires modification of settings before it   #
#            can be run.  Be sure to check for typos before running. #
#            A future version will have a config section at the top. #
######################################################################

####################################################################
# Recommandations:                                                 #
#                                                                  #
# 1) Once this is built, commit changes to create a local image.   #
# 2) After deployment, delete these build scripts to minimize risk #
#    of password exposre.                                          #
# 3) See https://github.com/ubccr/mokey for more detail and other  #
#    settings/features.                                            #
####################################################################

#----------------#
# config section #
#----------------#

DOMAIN="example.com"
SERVER="ipa.example.com"
REALM="EXAMPLE.COM"
IPA_USER="bob"
IPA_PASS="BoBsPaSsWoRd"
DB_PASS="DbPaSsWoRd"

# where the value for:
# - DOMAIN is LDAP domain (lower case)
# - SERVER is the hostname of the IPA server (lower case)
# - REALM is the kerberos domain (UPPER CASE)
# - IPA_USER is the account that can change other users' passwords
# - IPA_PASS is the password for the above
# - DB_PASS can be any password (to be used by mokey) to access the db

### ********* Don't edit below this line ********* ###

# set up the database
mysqladmin create mokey
mysql -u root mokey < /usr/share/mokey/ddl/schema.sql
mysql -u root -e "grant all on mokey.* to 'mokey'@localhost identified by '$DB_PASS'"


echo 'Cteating the folder for the keytab'
mkdir /etc/mokey/keytab

echo ''
echo 'Installing the Kerberos client'
echo ''

#-----------------------------------#
# Following installs the IPA client #
#-----------------------------------#

ipa-client-install -U --domain $DOMAIN --server $SERVER --realm $REALM -p $IPA_USER  -w $IPA_PASS --force-join

# where
#  -U                           tells the client to perform a non-interactive (i.e., unattended) install
#  --domain ARG         the AD domain (lower case)
#  --server ARG         the FreeIPA server's hostname
#  --realm ARG          the Kerberos realm (UPPER CASE)
#  -p ARG               the IPA account that can manage user accounts
#  -w ARG               the password for the above account
#  --force-join         (optional)

# Note: If you leave off the above "--force-join", you'll need to
#       delete the following on the IPA server before you can
#       attempt another install:
#       - Identity -> Users -> mokeyapp
#       - Identity -> Hosts -> this mokey server's name
#       - IPA Server -> Roles -> Mokey User Manager

echo ''
echo 'Registering the mokey server with the domain'
echo ''

#--------------------------------------------#
# Following logs onto the IPA server         #
# Note: must already exist on the IPA server #
#--------------------------------------------#

echo -n "$IPA_PASS" | kinit $IPA_USER

#------------------------------------------------------#
# Folling adds the User Manager role on the IPA server #
#------------------------------------------------------#

ipa role-add 'Mokey User Manager' --desc='Mokey User management'

#---------------------------------------------------------------------#
# Following adds the User Admin privilege to the User Manager account #
#---------------------------------------------------------------------#

ipa role-add-privilege 'Mokey User Manager' --privilege='User Administrators'

#----------------------------------------------------------------------------#
# Following creates the mokeyapp account (Note: used in the last line below) #
#----------------------------------------------------------------------------#
ipa user-add mokeyapp --first Mokey --last App

#-----------------------------------------------------------#
# Following adds the mokeyapp user to the User Manager role #
#-----------------------------------------------------------#

ipa role-add-member 'Mokey User Manager' --users=mokeyapp

#-------------------------------------------------------#
# Following pulls mokeyapp's keytab from the IPA server #
#-------------------------------------------------------#

ipa-getkeytab -s $SERVER -p mokeyapp -k /etc/mokey/keytab/mokeyapp.keytab

#-----------------------------------------------------------------------------#
# Following two modifies the ownership and permissions on the mokeyapp keytab #
#-----------------------------------------------------------------------------#

chmod 640 /etc/mokey/keytab/mokeyapp.keytab
chgrp mokey /etc/mokey/keytab/mokeyapp.keytab

echo ''
echo '=== Configuring the Mokey application ==='
echo ''

#------------------------------------------------------------------------------------------------#
# Following modifies mokey's config file and tells mokey how to connect to the internal database #
#------------------------------------------------------------------------------------------------#

sed -i "s/^dsn: .*/dsn: \"mokey:$DB_PASS@\/mokey?parseTime=true\"/" /etc/mokey/mokey.yaml

#---------------------------------------------------------------------------------#
# Following modifies mokey's config file and sets the port on which mokey listens #
#---------------------------------------------------------------------------------#

sed -i 's/^port: .*/port: 8084/' /etc/mokey/mokey.yaml

#---------------------------------------------------------------------------------#
# Following modifies mokey's config file and tells it to listen on all interfaces #
#---------------------------------------------------------------------------------#

sed -i 's/^bind: .*/bind: "0.0.0.0"/' /etc/mokey/mokey.yaml

#------------------------------------------------------------------------#
# Following modifies mokey's config file and sets the authentication key #
#   The key is created by running:  openssl rand -hex 32                 #
#------------------------------------------------------------------------#

sed -i 's/^auth_key: .*/auth_key: 0e7ced7fdda0758df8bde1becca6ac4fe985f4f68643fdf3369c0cd99e6ef243/' /etc/mokey/mokey.yaml

#--------------------------------------------------------------------#
# Following modifies mokey's config file and sets the encryption key #
#   Again, the key is created by running:  openssl rand -hex 32      #
#--------------------------------------------------------------------#

sed -i 's/^enc_key: .*/enc_key: 8fa246f510b70e770ffd79c494e575d99e13c56305d04f2e738f1c538c243372/' /etc/mokey/mokey.yaml

#-----------------------------------------------------------------------------------#
# Following modifies mokey's config file and tells mokey where its keytab is stored #
#-----------------------------------------------------------------------------------#

sed -i 's/^keytab: .*/keytab: \/etc\/mokey\/keytab\/mokeyapp.keytab/' /etc/mokey/mokey.yaml

#--------------------------------------------------------------------------------------------------#
# Following modifies mokey's config file and sets the Kerberos user to what was created much above #
#--------------------------------------------------------------------------------------------------#

sed -i 's/^ktuser: .*/ktuser: "mokeyapp"/' /etc/mokey/mokey.yaml

#-----------------------------------------------------#
# Following sets the path prefix for the external URL #
#-----------------------------------------------------#

sed -i 's/^# path_prefix: .*/path_prefix: "\/up"/' /etc/mokey/mokey.yaml

#-------------------------------#
# Following enables the captcha #
#-------------------------------#

sed -i 's/^# enable_captcha: .*/enable_captcha: true/' /etc/mokey/mokey.yaml

#-----------------------------------------------#
# Following disables account creation via Mokey #
#-----------------------------------------------#

sed -i 's/^# enable_user_signup: .*/enable_user_signup: false/' /etc/mokey/mokey.yaml

#--------------------------------------------------------------------#
# Following removes the "Forgot Password" prompt from the login page #
#--------------------------------------------------------------------#

sed -i '/help-block text-center/d' /usr/share/mokey/templates/login.html

#----------------------------------------------------------------------#
# Following removes options from the account page #
#----------------------------------------------------------------------#

sed -i '/OTP Tokens/d' /usr/share/mokey/templates/layout.html
sed -i '/Two-Factor Auth/d' /usr/share/mokey/templates/layout.html

