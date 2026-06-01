# OpenVPN Batch Client Generation Guide

## 1. Overview
This project provides an automated solution for generating OpenVPN client certificates and fully working inline `.ovpn` configuration files for a large group of students. The process is handled by a custom Bash script designed to be idempotent and non-interactive.

## 2. Environment Configuration
The system is configured with the following paths:
- **EasyRSA Directory:** `/etc/openvpn/server/easy-rsa`
- **PKI Directory:** `/etc/openvpn/server/easy-rsa/pki`
- **Client Output Directory:** `/etc/openvpn/client`
- **CA Certificate:** `/etc/openvpn/server/easy-rsa/pki/ca.crt`
- **TLS Crypt Key:** `/etc/openvpn/server/tc.key`
- **Template OVPN:** `/home/joker/joker.ovpn` (Read-only)

## 3. The Generation Script (`generate_clients.sh`)
The script `generate_clients.sh` automates the following steps for each student:
1. **Dependency Check:** Verifies that root privileges, EasyRSA, and all required keys/templates exist.
2. **Directory Setup:** Ensures the output folder `/etc/openvpn/client` exists.
3. **Certificate Generation:** Uses EasyRSA in `--batch` mode to generate a private key and sign a client certificate without prompts.
4. **OVPN Assembly:** 
   - Copies the `joker.ovpn` template.
   - Strips existing security tags to prevent conflicts.
   - Appends the CA certificate, student certificate, student private key, and the `tls-crypt` key inline.

### Usage
To run the script and regenerate clients:
```bash
sudo bash /home/joker/generate_clients.sh
```

## 4. Technical Corrections Applied
During development, the following critical fixes were implemented to ensure connectivity:
- **Key Path Correction:** The initial configuration expected `ta.key`. It was corrected to `tc.key` to match the server's configuration.
- **Security Protocol Alignment:** The configuration was updated from `<tls-auth>` to `<tls-crypt>`. OpenVPN considers these mutually exclusive; using the wrong tag results in a connection failure.
- **Inline Extraction:** The script uses `awk` to extract only the certificate portion from the EasyRSA output, ensuring the `.ovpn` files remain clean and compatible with all clients.

## 5. List of Generated Students
A total of 32 student configurations were generated:
- FilipAnastasovski, SashkoAngelovski, EmaArsova, KirilAtanasoski, NikolaBanskolievBabalj, PetarBozinovski, StefanBozinovski, FilipBojadzievski, ViktorijaBunteska, VladimirVeshoski, DraganDoncevski, MarijaIgnatoska, DanielaJovanovska, MarkoKraljev, LeonidKrstevski, HristinaKrstova, LoraMishevska, AndrejNaumov, SandraNedanovska, IlinaNeckoska, MateaPanajotova, LeonidPetrusevski, TimotejRisteski, PetarSimena, IvanStancev, HristijanStojanoski, NejraSuljovikj, ElenaTaseva, DespinaTonevska, ZaninaHadziVasileva, TeodoraCvetkovska, BorisCaushevski.

## 6. Testing and Verification
### Server Side
Check that files exist in the output directory:
```bash
sudo ls -la /etc/openvpn/client/
```

### Client Side (Student Instructions)
1. **Download:** Get your specific `.ovpn` file (e.g., `TimotejRisteski.ovpn`).
2. **Import:** Use an OpenVPN client (OpenVPN Connect, Tunnelblick, or Linux CLI).
3. **Connect:** Toggle the connection to "On".
4. **Verify:** 
   - Visit [ifconfig.me](https://ifconfig.me) to check if your IP matches the server (`185.83.253.226`).
   - Ping the gateway: `ping 10.8.0.1`.
