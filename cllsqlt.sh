#!/bin/bash 

DEBUG=false 
VERBEUX=true 

[[ $VERBEUX = true ]] && echo " 
	Bonjour à tous, c'est Nothus ! 
	[# CLLSQLT : centralisation des logs Linux - via SQLITE3] 
	>>> hors SUDO, point de salut 
	>>> DEBUG = $DEBUG
	>>> VERBEUX = $VERBEUX 

	0. déploiement de l'environnement de travail (SQLITE3) 
" # ----------------------------------------------------- 

(apt-get --assume-yes install sqlite3 1> /dev/null || (echo "ERREUR d'environnement" && exit 1))


[[ $VERBEUX = true ]] && echo "
	1. démarrage et préparation de la base
" # ----------------------------------------------------- 

sqlite3 /var/log/auth.log.db 'CREATE TABLE IF NOT EXISTS "enregistrement" ( "id" INTEGER PRIMARY KEY AUTOINCREMENT, "mois" TEXT NOT NULL DEFAULT "ERR", "jour" TEXT NOT NULL DEFAULT "ERR", "heure" TEXT NOT NULL DEFAULT "ERR", "machine" TEXT NOT NULL DEFAULT "ERR", "processus" TEXT DEFAULT "ERR", "message" TEXT DEFAULT "ERR" );' 2>&1

sqlite3 /var/log/auth.log.db 'CREATE INDEX IF NOT EXISTS "date" ON "enregistrement" ( "mois", "jour", "heure" );'  2>&1

sqlite3 /var/log/auth.log.db 'CREATE UNIQUE INDEX IF NOT EXISTS "general" ON "enregistrement" ( "mois", "jour", "heure", "machine", "processus", "message" );'  2>&1 


[[ $VERBEUX = true ]] && echo "
	2. préparation de l'expression régulière 
" # ----------------------------------------------------- 

REGEX_mois="([a-zA-Z]{3})"
REGEX_jour="([0-9]{2})"
REGEX_heure="(([0-9]{2}|\:){5})"
REGEX_machine="([a-zA-Z]+)"
REGEX_processus="([^[:blank:]]+)\:" 
REGEX_message="(.*)?"

REGEX="^$REGEX_mois[[:space:]]+$REGEX_jour[[:space:]]+$REGEX_heure[[:space:]]+$REGEX_machine[[:space:]]+$REGEX_processus[[:space:]]+$REGEX_message$"


[[ $VERBEUX = true ]] && echo "
	3. lecture ligne-à-ligne et création de la requête 
" # ----------------------------------------------------- 

DATA=""

while read ligne
do
  if [[ "$ligne" =~ $REGEX ]] ; then  
    extrait_date_mois=${BASH_REMATCH[1]}
    extrait_date_jour=${BASH_REMATCH[2]}
    extrait_date_heure=${BASH_REMATCH[3]} 
    extrait_machine=${BASH_REMATCH[5]} 
    extrait_processus=${BASH_REMATCH[6]}  
    extrait_message=${BASH_REMATCH[7]} 
    if [[ $DEBUG = true ]] ; then echo "ok" 
	    echo "Traitement de l'entrée du $extrait_date_jour/$extrait_date_mois à $extrait_date_heure"
	    echo "sur $extrait_machine via $extrait_processus :" 
		echo "	$extrait_message" 
	fi   
	DATA="$DATA INSERT OR IGNORE INTO \"enregistrement\" 
	(
		id, 
		mois, 
		jour, 
		heure, 
		machine, 
		processus, 
		message 
	) VALUES ( 
		NULL, 
		\"${extrait_date_mois//\"/ }\", 
		\"${extrait_date_jour//\"/ }\", 
		\"${extrait_date_heure//\"/ }\", 
		\"${extrait_machine//\"/ }\", 
		\"${extrait_processus//\"/ }\", 
		\"${extrait_message//\"/ }\" 
	);" 
  fi 
done < /var/log/auth.log

[[ $VERBEUX = true ]] && echo " 
	4. insertion dans la base 
" # ----------------------------------------------------- 

sqlite3 /var/log/auth.log.db <<< "$DATA" || (echo "erreur lors de l'insertion !" && exit 1) 

[[ $VERBEUX = true ]] && echo " 
	5. c'est fini ! merci de votre retour et bonne route 
" # ----------------------------------------------------- 

