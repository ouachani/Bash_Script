#!/bin/sh
# variable 
CONNECT_OPTION="set ftp:ssl-allow no; set net:reconnect-interval-base 5; set net:max-retries 5 ; set net:timeout 5"
DATE=`date +%Y""%m""%d"-"%H""%M`
login="GLPROD,UnCrop4GL"
##AO
RPU_USER=RPU_USER
RPU_PASS=RPU_PASS
RPU_HOST=RPU_HOST
# crée la liste des fichier
##AO
sshpass -p "$RPU_PASS" ssh $RPU_USER@$RPU_HOST "ls  /appli/hybris/impex/export/data/outgoing/uncrop | grep -E xml " > /tmp/tmp_file_.txt  
##AO
[[ `cat /tmp/tmp_file_.txt | wc -l` -eq 0 ]] && echo "Il n'a pas de fichier à la source - Sortie normale du script" && exit 0
# récuperer les fichier
##AO
sshpass -p "$RPU_PASS" rsync -azv  --include="xml" --exclude='*/'  $RPU_USER@$RPU_HOST:/appli/hybris/impex/export/data/outgoing/uncrop/* /data/shooting/tmp_xml
# compresser les fichier
cd  /data/shooting/tmp_xml
for XML_FILE in `ls | grep -E xml`
    do
	     ALL="$ALL $XML_FILE"
	done ;
zip /data/shooting/resultats/xml/zip_xml_${DATE}.zip  ${ALL}
# envoyer les fichier compresser
cd /data/shooting/resultats/xml/
#lftp -u "$login" sftp://media.enumeris.com -p 2222  -e "${CONNECT_OPTION}; cd  ./csv_in ;  put  zip_xml_${DATE}.zip ; exit "

sshpass -p "$RPU_PASS" sftp $RPU_USER@$RPU_HOST:/home/ansible/ <<< $'put zip_xml.zip'

##AO
if [ $? == 0 ]
then
	echo "Les fichiers ont bien été transferés vers FTP ${PART}"
	# archiver le zip en local
	cp -p  /data/shooting/resultats/xml/zip_xml_${DATE}.zip /data/shooting/archives/xml
	# archiver la liste des fichier copier sur le serveur souce
	ALL_FILE=`cat /tmp/tmp_file_.txt | tr "\n" "\ " | sed 's/  /\n\n/g'`
	##AO
	sshpass -p "$RPU_PASS" ssh $RPU_USER@$RPU_HOST "cd /appli/hybris/impex/export/data/outgoing/uncrop && cp -p  ${ALL_FILE} /appli/hybris/impex/export/data/outgoing/uncrop/archive"
	if [ $? == 0 ]
	then
		echo "Les fichiers ont  bien été archivés"
	else
		echo "Erreur d'archivage des fichiers"
	fi
else
	echo "Accès FTP KO- Le tranfert des fichiers XML a échoué"
fi

echo " --------- Fin de transfert ---------- "