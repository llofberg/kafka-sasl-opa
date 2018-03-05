#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=TEST.CONFLUENT.IO}
: ${DOMAIN_REALM:=kerberos.kafkasecurity_default}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=admin}
: ${KERB_ADMIN_PASS:=admin}

create_config() {
  : ${KDC_ADDRESS:=$(hostname -f)}

  cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 # WARNING: We use weaker key types to simplify testing as stronger key types
 # require the enhanced security JCE policy file to be installed. You should
 # NOT run with this configuration in production or any real environment. You
 # have been warned.
 # default_tkt_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 # default_tgs_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1
 # permitted_enctypes = des-cbc-md5 des-cbc-crc des3-cbc-sha1

 default_tkt_enctypes = rc4-hmac aes256-cts aes128-cts des3-cbc-sha1 des-cbc-md5 des-cbc-crc
 default_tgs_enctypes = rc4-hmac aes256-cts aes128-cts des3-cbc-sha1 des-cbc-md5 des-cbc-crc
 permitted_enctypes   = rc4-hmac aes256-cts aes128-cts des3-cbc-sha1 des-cbc-md5 des-cbc-crc

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM
EOF

cat>/var/kerberos/krb5kdc/kdc.conf<<EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 $REALM = {
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  # WARNING: We use weaker key types to simplify testing as stronger key types
  # require the enhanced security JCE policy file to be installed. You should
  # NOT run with this configuration in production or any real environment. You
  # have been warned.
  master_key_type = des3-hmac-sha1
  supported_enctypes = arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
  default_principal_flags = +preauth
 }
EOF
}

create_db() {
  /usr/sbin/kdb5_util -P $KERB_MASTER_KEY -r $REALM create -s
}

start_kdc() {
  mkdir -p /var/log/kerberos

  /etc/rc.d/init.d/krb5kdc start
  /etc/rc.d/init.d/kadmin start

  chkconfig krb5kdc on
  chkconfig kadmin on
}

restart_kdc() {
  /etc/rc.d/init.d/krb5kdc restart
  /etc/rc.d/init.d/kadmin restart
}

create_admin_user() {
  kadmin.local -q "addprinc -pw $KERB_ADMIN_PASS $KERB_ADMIN_USER/admin"
  echo "*/admin@$REALM *" > /var/kerberos/krb5kdc/kadm5.acl
}

main() {

  if [ ! -f /kerberos_initialized ]; then
    create_config
    create_db
    create_admin_user
    start_kdc

    touch /kerberos_initialized
  fi

  if [ ! -f /var/kerberos/krb5kdc/principal ]; then
    while true; do sleep 1000; done
  else
    start_kdc
    sleep 10

    kadmin.local -q "addprinc -randkey zookeeper/zookeeper.kafkasecurity_default@$REALM"
    kadmin.local -q "ktadd -norandkey -k /tmp/keytab/zookeeper1.keytab zookeeper/zookeeper.kafkasecurity_default@$REALM"

    kadmin.local -q "addprinc -randkey zkclient/zookeeper.kafkasecurity_default@$REALM"
    kadmin.local -q "ktadd -norandkey -k /tmp/keytab/zkclient1.keytab zkclient/zookeeper.kafkasecurity_default@$REALM"

    kadmin.local -q "addprinc -randkey kafka/broker.kafkasecurity_default@$REALM"
    kadmin.local -q "ktadd -norandkey -k /tmp/keytab/broker1.keytab kafka/broker.kafkasecurity_default@$REALM"

    kadmin.local -q "addprinc -randkey saslproducer/producer.kafkasecurity_default@$REALM"
    kadmin.local -q "ktadd -norandkey -k /tmp/keytab/saslproducer.keytab saslproducer/producer.kafkasecurity_default@$REALM"

    kadmin.local -q "addprinc -randkey saslconsumer/consumer.kafkasecurity_default@$REALM"
    kadmin.local -q "ktadd -norandkey -k /tmp/keytab/saslconsumer.keytab saslconsumer/consumer.kafkasecurity_default@$REALM"
    echo DONE
    tail -F /var/log/kerberos/krb5kdc.log
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"