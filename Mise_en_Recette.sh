#--------------------------------------#
#	Script de MER Hybris/PCM       #
#		V 1.0		       #
#--------------------------------------#

actuelle=$(cat /app/hybris_version.tag)

#---------------------------
# Verif du user d'execution
#---------------------------

LUSER=$(whoami)
RUSER=hybris

if [ "$LUSER" != "$RUSER" ]; then
        echo "${ROUGE} Executable avec l'utilisteur $RUSER uniquement !${RESETCOLOR}"
        exit 1
fi

#------------------------------------------
#Vérif que la variable $1 n'est pas à vide
#------------------------------------------
if [ $# = 0 ]; then
		echo "Merci de renseigner un numéro de version."
        echo "Usage : ./script <version>"
        echo "Exemple : ./MER.sh 4.14.10"
        exit
fi

#---------------------------
#Copie des sources en local
#---------------------------
if [ ! -d /data/source_PCM/$1 ]; then
	scp -r xv34i351:/data/source_PCM/livraison/"$1" /data/source_PCM
	if [ $? = 0 ]; then
		echo "--- Copie des sources : OK"
	else
		echo "*** La copie des sources a échoué ***"
		exit 1
	fi
fi

#------------------------------------
#Verification du contenu des sources
#------------------------------------
if [ ! -f /data/source_PCM/$1/hybrisServer-Platform.zip ] || [ ! -f /data/source_PCM/$1/hybrisServer-AllExtensions.zip ]; then
	echo "*** Il manque des fichiers ***"
	exit 1
	
fi

echo $actuelle >/app/previous.tag
#-------------------------------------------
#Verif de la version actuellement installée
#-------------------------------------------
if [ "$1" = $actuelle ]; then
	echo "*** Cette version est déjà installée ***"
	exit 1
fi

#-------------------------------------------
#Suppression d'éventuels résidus de MER passées
#-------------------------------------------

rm -f /app/*.zip

#-------------------------------------------
#Déplacement des sources pour déploiement
#-------------------------------------------
cp /data/source_PCM/"$1"/*.zip /app

#-------------------------------------------
#Modif du tag de version
#-------------------------------------------
echo "$1" >/app/hybris_version.tag

#-------------------------------------------
#Arret applicatif 
#-------------------------------------------
/etc/init.d/hybris_pcm stop
if [ $? = 0 ]; then
	echo "--- Arret de l'instance 1 : OK"
else
	echo "*** impossible de stopper l'instance 1"
	exit 1
fi

/etc/init.d/hybris_pcm2 stop
if [ $? = 0 ]; then
	echo "--- Arret de l'instance 2 : OK"
else
	echo "*** impossible de stopper l'instance 2"
	exit 1
fi

#-------------------------------------------
#Suppression de /bin
#-------------------------------------------
rm -rf /app/hybris/bin
rm -rf /app/hybris_2/bin

#-------------------------------------------
#Decompression
#-------------------------------------------
cd /app
unzip hybrisServer-Platform.zip
if [ $? = 0 ]; then
	echo "--- Decompression de hybrisServer-Platform.zip : OK"
else
	echo "*** Impossible de décompresser hybrisServer-Platform.zip ***"
	exit 1
fi

unzip hybrisServer-AllExtensions.zip
if [ $? = 0 ]; then
	echo "--- Decompression de hybrisServer-AllExtensions.zip : OK"
else
	echo "*** Impossible de décompresser hybrisServer-AllExtensions.zip ***"
	exit 1
fi

#-------------------------------------------
#Chargement des variables d'environnement instance 1
#-------------------------------------------
cd /app/hybris/bin/platform
if [ $? -ne 0 ]; then
	echo "*** Impossible d'acceder à /app/hybris/bin/platform"
	exit 1
fi
. ./setantenv.sh
if [ $? -ne 0 ]; then
	echo "*** Impossible de charge setantenv.sh ***"
	exit 1
fi

#-------------------------------------------
#Compilation des sources instance 1
#-------------------------------------------
ant clean all | tee /data/hybris_log/ant_clean_all_"$1".log && cat /data/hybris_log/ant_clean_all_"$1".log | grep "BUILD SUCCESSFUL" #Controle

if [ $? = 0 ]; then
	echo "--- Compilation de l'intance 1 = OK"
else
	echo "*** Impossible de compiler l'instance 1 ! Cf. /data/hybris_log/ant_clean_all_"$1".log pour plus de détails ***"
	exit 1
fi

#-------------------------------------------
#Copie de /bin pour la seconde instance
#-------------------------------------------
cp -r /app/hybris/bin /app/hybris_2/

#-------------------------------------------
#Chargement des variables d'environnement instance 2
#-------------------------------------------
cd /app/hybris_2/bin/platform
if [ $? -ne 0 ]; then
	echo "*** Impossible d'acceder à /app/hybris_2/bin/platform"
	exit 1
fi
. ./setantenv.sh
if [ $? -ne 0 ]; then
	echo "*** Impossible de charge setantenv.sh ***"
	exit 1
fi

#-------------------------------------------
#Compilation des sources instance 2
#-------------------------------------------
ant clean all | tee /data/hybris_log_2/ant_clean_all_"$1".log && cat /data/hybris_log_2/ant_clean_all_"$1".log | grep "BUILD SUCCESSFUL" #Controle

if [ $? = 0 ]; then
	echo "--- Compilation de l'intance 2 = OK"
else
	echo "*** Impossible de compiler l'instance 2 ! Cf. /data/hybris_log_2/ant_clean_all_"$1".log pour plus de détails ***"
	exit 1
fi


#--------------------------------
# Suppressions des zip dans /app
#--------------------------------
rm -f /app/*.zip

