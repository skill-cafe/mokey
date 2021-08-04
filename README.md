# mokey

Mokey is a web-based tool to allow for changing of FreeIPA passwords.  The scripts in this repo create a Docker container which runs Mokey on a non-standard port.

I've automated parts of the install process and will be improving/simplifying it as time becomes available.

## Assumptions

* Mokey is intended to run at an IP separate from FreeIPA (i.e., it shouldn't be run on the FreeIPA server)
* The scripts in this repo contain passwords.  Be sure to delete these files once Mokey is installed.
* Installation and set up of FreeIPA is covered under a separate build process.
* Configuration of any intervening reverse proxy is not covered by this README.

## Files in this repo

* ***build*** - This is the script to deploy the container and partially configure Mokey.  *Note: this script requires editing before running it.*
* ***build-image*** - This is the script to build the Docker image from the Dockerfile.
* ***destroy*** - This script stops the mokey container and deletes it.
* ***Dockerfile*** - This is the build recipe for the Mokey image.
* ***instll.sh*** - Adds the container as an IPA client and creates the mokeyapp user account/role on the IPA server.
* ***mokey-0.5.6-1.el7.x86_64*** - RPM for the mokey service

## Install

1) Run the following to download the baseline image.
    ```c
    docker pull jrei/systemd-fedora
    ```
    
    Above downloads a Fedora base image, upon which the Mokey container will be built.

2) Download this code by clicking on the download link (upper-right of this repository's page).  Unzip (or untar) it in a working directory.

3) Edit the "build" script and modify the values for ADMINPASS and DBPASS in lines 3 and 4.

4) Edit "install.sh" and change the variables in the config section of the install.sh script.  This script performs the following:
* configures the internal database
* registers the container with the FreeIPA server
* creates the mokeyapp account and roles on the FreeIPA server
* modifies the mokey service to allow/disallow various features
* enables and starts the databaase and the mokey service

5) Create the Docker image by running:
    ```c
    ./build-image
    ```

6) Create the container by running:
    ```c
    ./build
    ```

7) Connect to the container by running:
    ```c
    docker exec -it mokey bash
    ```

8) (While in the mokey container) Add an entries to /etc/hosts for the FreeIPA server.

9) (While in the mokey container) Install the mokey rpm by running:
   ```c
   dnf install -y /mokey-0.5.6-1.el7.x86_64.rpm
   ```

10) (While in the mokey container) Enable and start the MariaDB service by running:
   ```c
   systemctl enable mariadb
   systemctl start mariadb
   ```

11) (While in the mokey container) Lock down the MariaDB service by running:
    ```c
    mysql_secure_installation
    ```

    Above will ask a number of questions.

12) (While in the mokey container) Edit /etc/mokey/mokey.yaml and change the values for the following variables:
* ***dsn*** - This should container the username, password, and database name of the MariaDB database
* ***port*** - Set this to the port on which the service should listen.  It should be the same as the target port in the build script (e.g., 8084)
* ***bind*** - Set this to "0.0.0.0".  This allows IPs (external to Docker) to connect to the container.
* ***auth_key*** - This needs to be set to a 32-bit string.  To generate it, see below.
* ***enc_key*** - This also needs to be set to a 32-bit string.  Again, see below.
* ***ipahost*** - This should be set to the FQDN for the FreeIPA server.
* ***keytab*** - This should be set to the full path for the keytab (e.g., "/etc/mokey/keytab/mokeyapp.keytab")
* ***ktuser*** - This should be set to the user created in the "ipa user-add" line of the install.sh script. (e.g., mokeyapp)
* ***develop*** - This should be set to false, unless you're testing/troubleshooting.
    
    Remaining values can be left as is.

    Note: if you wish to disable new account creation, uncomment the "enable_user_signup" line and set it to false.

    Note: the ktuser value is the username created in the install.sh script, NOT the IPA admin user.

    Note: To create the 32-bit auth_key and enc_key values, use "openssl rand -hex 32".

13) (While in the mokey container) - Enable and start the mokey service by running:
    ```c
    systemctl enable mokey
    systemctl start mokey
    ```

### To do
* add in steps to delete files containing usernames and passwords (or make the files self-removing)
* create a central config file for usernames and passwords

## Sources

* https://hub.docker.com/r/jrei/systemd-fedora
* https://github.com/ubccr/mokey
* https://github.com/ubccr/mokey/issues/42
