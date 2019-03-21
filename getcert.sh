#!/bin/bash

# what, no hostname?
if [ -z "$1" ]; then
    echo "must provide a host name"
    exit 1
fi

if [ "$2" == "-f" ]; then
	rm "$1.mohawkrockrides_https.csr"
fi

# did we already issue a CSR?
if [ -f "$1.mohawkrockrides_https.csr" ]; then
    echo "$1 already has a CSR!"
    exit 1
fi

# -config is specified during the certificate request creation
# -extension XXX and -extfile are for the signing of the certificate
# the XXX must match a secion in the conf file (currently v3_req)
# do we have a conf or ext file?
if [ -f "$1.mohawkrockrides_https.ext" ]; then
    echo "using conf file $1.mohawkrockrides_https.conf"
    conffile="-config $1.mohawkrockrides_https.conf "
    extfile="-extensions v3_req -extfile $1.mohawkrockrides_https.conf"
else
    echo "no ext file, using default"
    conffile=""
    extfile=""
fi

#openssl genrsa -des3 -out $1.mohawkrockrides.key 4096
openssl genrsa -out $1.mohawkrockrides_https.key 4096
openssl req -new -key $1.mohawkrockrides_https.key -out $1.mohawkrockrides_https.csr $conffile 
openssl x509 -req -in $1.mohawkrockrides_https.csr -CA mohawkrockrides_ca.pem -CAkey mohawkrockrides_ca.key -CAcreateserial -out $1.mohawkrockrides_https.crt -days 3650 -sha512 $extfile
#openssl x509 -req -in $1.mohawkrockrides_https.csr -CA mohawkrockrides_ca.pem -CAkey mohawkrockrides_ca.key -CAcreateserial -out $1.mohawkrockrides_https.crt -days 3650 -sha512 $extfile
