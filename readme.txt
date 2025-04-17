-- go to C:\laragon\etc\bird_ssl --
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout shikra-papy.key -out shikra-papy.crt -config shikra-san.conf

-- ajout de certificat au windows --
-- execute avec powerShell --
Import-Certificate -FilePath "C:\laragon\etc\bird_ssl\shikra-papy.crt" -CertStoreLocation "Cert:\CurrentUser\Root"

-- Ajouter cela dans C:\Windows\system32\drivers\etc\hosts --
127.0.0.1      albatros.prx   #birds
127.0.0.1      buse.prx       #birds
127.0.0.1      cassi.prx      #birds