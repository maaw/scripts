#!/bin/sh

# Call fowsr and upload data to Wunderground

wsr="/usr/bin/fowsr -fw -n /mnt/sda2/%%s.log"
LOG=/mnt/sda2/wunderground.log

ID=$1
PASSWORD=$2
SLEEPTIME=15
ERRORS=0

WGET=http://weatherstation.wunderground.com/weatherstation/updateweatherstation.php

WGET="$WGET?action=updateraw&ID=$ID&PASSWORD=$PASSWORD&softwaretype=fowsr&"

rm -f $LOG
$wsr

logger "##Reporte de la estacion del clima##"
logger "Cantidad de lineas del log: `grep "date" $LOG -c`."

ERRORS=$((`grep "\-\-.\-" $LOG -c` + `grep "2880.0" $LOG -c`))
logger "$ERRORS errores detectados."

#Limpio errores
`sed -i '/--.-/d' $LOG`
`sed -i 's/2880.0/0.0/g' $LOG`

#Para quedarme la ultima linea.
`sed -i ':a;$q;N;'$(($1+2))',$D;ba' $LOG`

logger "Cantidad de lineas a enviar: "`grep "date" $LOG -c`. Enviando dentro de $SLEEPTIME segundos.



while read line
do
  WGET2="$WGET`echo $line`"
  #logger "URL vieja: $WGET2."
  
  #Reemplazo la fecha
  ORIGINALDATE=`echo $WGET2 | cut -d'&' -f 5`	 
  NEWDATE="dateutc="`date -u +"%Y-%m-%d+%H%3A%M%3A00"`
  NEWURL=${WGET2/$ORIGINALDATE/$NEWDATE}
  
  sleep $SLEEPTIME; 
  logger "Enviando datos: `echo $NEWURL | cut -d'&' -f 5-`."
  wget -O /dev/null "$NEWURL"
done < $LOG
