
$ cd /home/applis/ && rm -rf tmp/ && mkdir tmp\'"'
$ cd /home/applis/ && unzip -q /home/applis/ds/delivery/hybrisServer-Platform.zip -d tmp/ && unzip -q /home/applis/ds/delivery/hybrisServer-AllExtensions.zip -d tmp/ && unzip -q /home/applis/ds/delivery/hybrisServer-Config.zip -d tmp/ && unzip -q /home/applis/ds/delivery/hybrisServer-Licence.zip -d tmp/\'"'
// Stop Hybris
$ cd /home/applis/hybris/bin/platform/ && ./hybrisserver.sh stop\'"'
// Remove Old Backup
$ cd /home/applis/hybris/ && rm -rf bin.backup/ && rm -rf config.backup/\'"'
// Backup current Project
$ cd /home/applis/hybris/ && mv bin/ bin.backup/ && mv config/ config.backup/\'"'
// Deploy new files
$ cd /home/applis/tmp/hybris && mv bin/ /home/applis/hybris && mv config/ /home/applis/hybris\'"'
// Backup localextensions.xml file
//$ cd /home/applis/hybris/config/ && cp localextensions.xml localextensions.xml.backup\'"'
// Replace localextensions.xml
//$ cd /home/applis/tmp/hybris/config/ && cp localextensions.xml /home/applis/hybris/config/\'"'
// Replace local.properties with local from server
$ cd /home/applis/deployer/hybris/conf/ && cp int.bo1.local.properties ../../../hybris/config/local.properties\'"'
// Apply CRLF fix
$ cd /home/applis/deployer/ && ./fixcrlf.sh\'"'
// Compile server
$ cd /home/applis/hybris/bin/platform/ && . ./setantenv.sh && ant clean all -Dgrunt.ignore=true\'"'
//$ cd /home/applis/hybris/bin/platform/ && . ./setantenv.sh && ant server\'"'
// Updatesytem via fichier JSON
$ cd /home/applis/hybris/bin/platform/ && . ./setantenv.sh && ant updatesystem -Dgrunt.ignore=true -DconfigFile="/home/applis/hybris/config/json/updatesystem-prod.json" > /home/logs/hybris/updatesystem.log\'"'
// Start Hybris Server
$ cd /home/applis/hybris/bin/platform/ && ./hybrisserver.sh start\'"'        
$ cd /home/applis/ && rm -r tmp/\'"'