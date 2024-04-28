#!/bin/bash

#ini kasus kalau bikinnya pisah-pisah, bukan dengan network.sh
. scripts/utils.sh
export PATH=${PWD}/../bin:$PATH

function registerPeer() {
  PEER=$1

  PORT=7054

  infoln "Registering peer${PEER}"
  set -x
  fabric-ca-client register --caname ca-pemilihan --id.name peer${PEER} --id.secret peer${PEER}pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer${PEER} msp"
  set -x
  fabric-ca-client enroll -u https://peer${PEER}:peer${PEER}pw@localhost:$PORT --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/msp" --csr.hosts peer${PEER}.pemilihan.pemira.com --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/msp/config.yaml"

  infoln "Generating the peer${PEER}-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer${PEER}:peer${PEER}pw@localhost:$PORT --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls" --enrollment.profile tls --csr.hosts peer${PEER}.pemilihan.pemira.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer${PEER}.pemilihan.pemira.com/tls/server.key"
}

function createPemilihan() {
  mkdir channel-artifacts
  infoln "Enroll the CA admin"
  sleep 2
  mkdir -p organizations/peerOrganizations/pemilihan.pemira.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-pemilihan --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-pemilihan.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-pemilihan.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-pemilihan.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-pemilihan.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/config.yaml"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-pemilihan --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-pemilihan --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-pemilihan --id.name pemilihanadmin --id.secret pemilihanadminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls" --enrollment.profile tls --csr.hosts peer0.pemilihan.pemira.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/tlscacerts/ca.crt"

  # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/tlsca/tlsca.pemilihan.pemira.com-cert.pem"

  # Copy org1's CA cert to org1's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/ca"
  cp "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/ca/ca.pemilihan.pemira.com-cert.pem"

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/peers/peer0.pemilihan.pemira.com/tls/server.key"
  
  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/users/User1@pemilihan.pemira.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/users/User1@pemilihan.pemira.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://pemilihanadmin:pemilihanadminpw@localhost:7054 --caname ca-pemilihan -M "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/users/Admin@pemilihan.pemira.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/pemilihan/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/pemilihan.pemira.com/users/Admin@pemilihan.pemira.com/msp/config.yaml"

  registerPeer 1
}

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/pemira.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/pemira.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/pemira.com/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/pemira.com/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem" "${PWD}/organizations/ordererOrganizations/pemira.com/msp/tlscacerts/tlsca.pemira.com-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/pemira.com/tlsca"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem" "${PWD}/organizations/ordererOrganizations/pemira.com/tlsca/tlsca.pemira.com-cert.pem"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:8054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/pemira.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates, use --csr.hosts to specify Subject Alternative Names"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:8054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls" --enrollment.profile tls --csr.hosts orderer.pemira.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/pemira.com/orderers/orderer.pemira.com/msp/tlscacerts/tlsca.pemira.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:8054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/pemira.com/users/Admin@pemira.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/pemira.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/pemira.com/users/Admin@pemira.com/msp/config.yaml"
}
