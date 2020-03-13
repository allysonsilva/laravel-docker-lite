rm -rf server* client* ca*

# Creating own SSL CA to dump our self-signed certificate
openssl genrsa -out ca.key -aes256 8192
openssl req -new -x509 -nodes -extensions v3_ca -key ca.key -days 1024 -out ca.pem -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=authority/CN=MongoDB_CA_Certificate"

##############################
# Generate SERVER certificates
##############################

# Generate the Certificate Requests and the Private Keys
openssl req -newkey rsa:4096 -sha256 -nodes -keyout server.key -out server.csr -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=server/CN=127.0.0.1"
openssl req -newkey rsa:4096 -sha256 -nodes -keyout client.key -out client.csr -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=client/CN=MongoDB_Client_Certificate"

# Sign your Certificate Requests
openssl x509 -req -CA ca.pem -CAkey ca.key -set_serial 00 -days 365 -in server.csr -out server.crt
openssl x509 -req -CA ca.pem -CAkey ca.key -set_serial 00 -days 365 -in client.csr -out client.crt

# Concat each Node Certificate with its key
cat server.key server.crt > server.pem
cat client.key client.crt > client.pem
