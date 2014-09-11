#!/bin/bash

export CA_SUBJECT='/C=US/ST=California/L=SanFrancisco/CN=public.stacktira.domain.name'
export SERVER_SUBJECT='/C=US/ST=California/L=SanFrancisco/CN=public.stacktira.domain.name'
export CLIENT_SUBJECT='/C=US/ST=California/L=SanFrancisco/CN=public.stacktira.domain.name'

mkdir certs
cd certs

openssl genrsa -out privkey.pem 2048

openssl req -new -key privkey.pem -out cert.csr -subj $CA_SUBJECT
openssl req -new -x509 -key privkey.pem -out cacert.pem -days 1095 -subj $CA_SUBJECT

cat cacert.pem privkey.pem > ../sample/testing_stacktira.pem
cp cacert.pem ../sample/testing_stacktira_ca.crt

cd ..
rm -rf certs
