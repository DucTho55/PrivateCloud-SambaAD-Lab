#!/bin/bash
# Chan doan loi Mailcow Identity Sync "HTTP 401 for /users" (chi doc, khong in secret)
exec > >(tee /tmp/diag-sync.log) 2>&1
cd /opt/mailcow-dockerized && source mailcow.conf
q() { docker compose exec -T mysql-mailcow mysql -N -u"$DBUSER" -p"$DBPASS" "$DBNAME" -e "$1" 2>/dev/null; }

echo "== Cau hinh IdP trong Mailcow (khong gom secret) =="
q "SELECT \`key\`, \`value\` FROM identity_provider WHERE \`key\` NOT LIKE '%secret%';"
SECRET=$(q "SELECT \`value\` FROM identity_provider WHERE \`key\`='client_secret';")
echo "client_secret do dai: ${#SECRET}"

echo "== Keycloak env (hostname/proxy) =="
docker inspect cloud-lab-keycloak-keycloak-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E '^KC_(HOSTNAME|PROXY|HTTP)'
docker inspect cloud-lab-keycloak-keycloak-1 --format '{{json .Config.Cmd}}'

echo "== Lay token client_credentials tu container php-fpm =="
docker compose exec -T -e S="$SECRET" php-fpm-mailcow php -r '
$base="https://auth.ad.lab.test"; $realm="cloud-lab";
$c=curl_init("$base/realms/$realm/protocol/openid-connect/token");
curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>1,CURLOPT_POST=>1,CURLOPT_POSTFIELDS=>http_build_query(["grant_type"=>"client_credentials","client_id"=>"mailcow","client_secret"=>getenv("S")])]);
$r=curl_exec($c); $code=curl_getinfo($c,CURLINFO_HTTP_CODE);
echo "token HTTP $code\n"; $j=json_decode($r,true);
if(empty($j["access_token"])){ echo substr($r,0,300),"\n"; exit; }
$p=json_decode(base64_decode(strtr(explode(".",$j["access_token"])[1],"-_","+/")),true);
echo "iss=",$p["iss"]," azp=",$p["azp"]??"-","\n";
echo "realm-management roles=",json_encode($p["resource_access"]["realm-management"]["roles"]??null),"\n";
foreach(["/admin/realms/$realm/users?max=3","/admin/realms/$realm/users/count"] as $u){
  $c=curl_init($base.$u); curl_setopt_array($c,[CURLOPT_RETURNTRANSFER=>1,CURLOPT_HTTPHEADER=>["Authorization: Bearer ".$j["access_token"]]]);
  $r=curl_exec($c); echo "GET $u -> HTTP ",curl_getinfo($c,CURLINFO_HTTP_CODE)," ",substr($r,0,150),"\n";
}'

echo "== Keycloak log 5 phut =="
docker logs --since 5m cloud-lab-keycloak-keycloak-1 2>&1 | grep -vE 'full-scope' | grep -E 'WARN|ERROR' | tail -10
echo "DIAG_SYNC_DONE"
