# 1. Chemins
$sslPath = "C:\laragon\etc\bird_ssl"
$crtPath = "$sslPath\shikra-papy.crt"
$keyPath = "$sslPath\shikra-papy.key"
$confPath = "$sslPath\shikra-san.conf"

# 2. Créer le fichier de configuration SAN
@"
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca
prompt             = no

[req_distinguished_name]
C = MG
ST = Madagascar
L = Antananarivo
O = BirdsCorp
OU = Dev
CN = Vorona.co

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names

[alt_names]
DNS.1 = albatros.prx
DNS.2 = *.albatros.prx
DNS.3 = buse.prx
DNS.4 = *.buse.prx
DNS.5 = cassi.prx
DNS.6 = *.cassi.prx
"@ | Out-File -Encoding ASCII -FilePath $confPath

# 3. Générer la clé privée et certificat
$openssl = "C:\_APP\portable\OpenSSL\openssl.exe"
if (-Not (Test-Path $openssl)) {
    Write-Host "❌ OpenSSL non trouvé. Vérifie le chemin dans Laragon." -ForegroundColor Red
    exit 1
}

& $openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
    -keyout $keyPath -out $crtPath `
    -config $confPath

# 4. Vérifier la création
if ((Test-Path $crtPath) -and (Test-Path $keyPath)) {
    Write-Host "✅ Certificat et clé générés avec succès." -ForegroundColor Green
} else {
    Write-Host "❌ Échec de génération du certificat." -ForegroundColor Red
    exit 1
}

# 5. Importer dans le magasin SYSTÈME (LocalMachine\Root)
try {
    Import-Certificate -FilePath $crtPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
    Write-Host "✅ Certificat installé dans 'Autorités racines (LocalMachine)' pour tous les utilisateurs." -ForegroundColor Green
} catch {
    Write-Host "❌ Échec de l'installation du certificat dans le magasin système." -ForegroundColor Red
    exit 1
}
