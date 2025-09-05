#!/bin/bash
echo this is export_heizung_history.sh

SQLITE3='/usr/bin/sqlite3'
EXIT_CODE=0
RESPONSE=$(stat $SQLITE3) || EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo install SQLite
    apk add sqlite
fi

$SQLITE3 /config/home-assistant_v2.db "SELECT 'sensor.ebusd_sc_ebusd_sc_act_supplytemp', state, datetime(last_updated_ts,'unixepoch', 'localtime') FROM states WHERE metadata_id = (SELECT  metadata_id FROM states_meta WHERE entity_id = 'sensor.ebusd_sc_ebusd_sc_act_supplytemp') AND last_updated_ts > unixepoch(datetime('now', '-1 day'))" >> /config/userfiles/heizung_history.csv
$SQLITE3 /config/home-assistant_v2.db "SELECT 'sensor.ebusd_hc1_ebusd_hc1_externaltemperature_externaltemperature', state, datetime(last_updated_ts,'unixepoch', 'localtime') FROM states WHERE metadata_id = (SELECT  metadata_id FROM states_meta WHERE entity_id = 'sensor.ebusd_hc1_ebusd_hc1_externaltemperature_externaltemperature') AND last_updated_ts > unixepoch(datetime('now', '-1 day'))" >> /config/userfiles/heizung_history.csv
$SQLITE3 /config/home-assistant_v2.db "SELECT 'sensor.ebusd_sc_ebusd_sc_act_operatingphase', state, datetime(last_updated_ts,'unixepoch', 'localtime') FROM states WHERE metadata_id = (SELECT  metadata_id FROM states_meta WHERE entity_id = 'sensor.ebusd_sc_ebusd_sc_act_operatingphase') AND last_updated_ts > unixepoch(datetime('now', '-1 day'))" >> /config/userfiles/heizung_history.csv
$SQLITE3 /config/home-assistant_v2.db "SELECT 'sensor.shellyplusht_c049ef88df9c_temperature', state, datetime(last_updated_ts,'unixepoch', 'localtime') FROM states WHERE metadata_id = (SELECT  metadata_id FROM states_meta WHERE entity_id = 'sensor.shellyplusht_c049ef88df9c_temperature') AND last_updated_ts > unixepoch(datetime('now', '-1 day'))" >> /config/userfiles/heizung_history.csv

