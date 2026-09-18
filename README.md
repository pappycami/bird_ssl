# bird_ssl 🐦

Configuration **HTTPS locale** pour Laragon : Apache fait office de *reverse proxy* SSL devant les services de dev, via des domaines maison en `*.prx` (thème oiseaux).

Un seul certificat auto-signé avec **SAN + wildcards** (`shikra-papy.crt`) couvre tous les domaines — après import dans Windows, plus d'avertissement navigateur.

## Fonctionnement

```
Navigateur ──https://albatros.prx──▶ Apache (Laragon) ──proxy──▶ http://localhost:8080
```

Chaque conf dans `bird_confs/` déclare deux `<VirtualHost>` :

- `*:80` → proxy HTTP simple vers le service local
- `*:443` → terminaison SSL (`SSLEngine on` + certificat) puis proxy vers le même service

Les vhosts utilisent des variables `define` (`SITE`, `CERT_NAME`, `BIRDS_SSL`, `PROXY_PASS`) : pour ajouter un domaine, il suffit de copier un fichier et changer `SITE` et `PROXY_PASS`.

## Domaines et ports

| Domaine        | Proxy vers            |
|----------------|-----------------------|
| albatros.prx   | http://localhost:8080 |
| buse.prx       | http://localhost:3000 |
| cassi.prx      | http://localhost:5173 |
| dorian.prx     | http://localhost:9200 |
| ewan.prx       | http://localhost:8083 |
| faucon.prx     | http://localhost:8089 |

Les sous-domaines (`*.albatros.prx`, etc.) sont aussi couverts par le certificat et par `ServerAlias`.

## Structure

```
bird_ssl/
├── shikra-san.conf                  # Config OpenSSL : SAN de tous les domaines (*.prx + wildcards)
├── shikra-papy.crt / .key           # Certificat + clé (générés, ignorés par git)
├── bird_confs/                      # Confs vhost Apache (une par domaine)
│   └── <domaine>.prx.conf
└── auto-scripts/
    ├── lanch.ps1                    # Lance le setup (gère l'ExecutionPolicy)
    └── setup-faucon-ssl-admin.ps1   # Génère SAN conf + certificat + import magasin système
```

## Installation

### 1. Activer les modules Apache

Dans `C:\laragon\bin\apache\httpd-xxx\conf\httpd.conf`, décommenter/ajouter :

```apache
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
```

### 2. Générer le certificat

**Automatique** (PowerShell en admin — vérifier le chemin d'OpenSSL dans le script) :

```powershell
C:\laragon\etc\bird_ssl\auto-scripts\lanch.ps1
```

Le script génère `shikra-san.conf`, le certificat (`openssl req -x509 -days 365 -newkey rsa:2048`), puis l'importe dans `Cert:\LocalMachine\Root`.

**Manuel** :

```bash
cd C:\laragon\etc\bird_ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout shikra-papy.key -out shikra-papy.crt -config shikra-san.conf
```

### 3. Enregistrer les vhosts

Copier les confs dans le dossier auto-vhosts de Laragon :

```
bird_confs\*.conf  →  C:\laragon\etc\apache2\sites-enabled
```

Puis redémarrer Apache.

### 4. Importer le certificat dans Windows

**Utilisateur courant** (PowerShell, pas d'admin requis) :

```powershell
Import-Certificate -FilePath "C:\laragon\etc\bird_ssl\shikra-papy.crt" -CertStoreLocation "Cert:\CurrentUser\Root"
```

**Tous les utilisateurs** (PowerShell en admin — c'est ce que fait le script auto) :

```powershell
Import-Certificate -FilePath "C:\laragon\etc\bird_ssl\shikra-papy.crt" -CertStoreLocation "Cert:\LocalMachine\Root"
```

### 5. Fichier hosts

Ajouter dans `C:\Windows\system32\drivers\etc\hosts` :

```
127.0.0.1      albatros.prx
127.0.0.1      buse.prx
127.0.0.1      cassi.prx
127.0.0.1      dorian.prx
127.0.0.1      ewan.prx
127.0.0.1      faucon.prx
```

## Ajouter un nouveau domaine

1. Ajouter `DNS.x = nouveau.prx` et `DNS.x+1 = *.nouveau.prx` dans `shikra-san.conf` (et régénérer + réimporter le certificat)
2. Créer `bird_confs/nouveau.prx.conf` en copiant une conf existante (`SITE` + `PROXY_PASS`)
3. Copier la conf vers `C:\laragon\etc\apache2\sites-enabled`
4. Ajouter la ligne `127.0.0.1  nouveau.prx` dans le hosts
5. Redémarrer Apache

## Renouvellement

Le certificat est valide **365 jours** : relancer simplement l'étape 2 (génération + import) à expiration.

## Notes

- `*.crt` et `*.key` sont dans `.gitignore` — ne jamais committer clé ni certificat.
- Certificat auto-signé, usage **local uniquement** (dev).
- Le script auto pointe vers `C:\_APP\portable\OpenSSL\openssl.exe` : adapter le chemin si besoin (sinon utiliser l'OpenSSL fourni avec Laragon).
