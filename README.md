# ha-history-exporter
A lightweight developer utility for [Home Assistant](https://www.home-assistant.io/) that regularly exports history data into a local CSV file.

## Features
- Periodically dumps Home Assistant history into CSV
- Configurable export interval
- Keeps data available outside the HA database
- Useful for long-term storage, backup or external analysis

## Use cases
- Archiving HA history data beyond the database retention period
- Feeding external scripts, dashboards or analytics pipelines
- Simple backup of historical state changes to file

## How to
Some time ago I wanted to monitor my gas heating system to find out about energy demand and temperature profiles. Mainly to assess whether I can replace the gas heating with a heat pump. So I bought an [eBUS Adapter](https://adapter.ebusd.eu/index.en.html) that was compatible with my heating system. Compatible but still tricky to install (I mounted an IP66 socket with a built-in USB port near the heating system and connected the adapter to the eBUS using two previously unused wires in a cable that, fortunately, was already available). The adapter could be connected via Wi-Fi and configured via the integrated web server. But how to get the heating data from the adapter into Home Assistant is another story, too long to tell here.
In any case, the data eventually arrived and was visualized very nicely.
![Home Assistant History](https://github.com/ThomasHeinrichSchmidt/ha-history-exporter/blob/main/media/ha-history.png?raw=true)
The blue curve shows the flow temperature at which the heating water enters the heating circuit (or hot water preparation).
The yellow curve indicates the outside temperature, the orange one the inside temperature. The bar at the top shows the operating status of the heating system, which is mostly off now in summer. I hope this gives me everything I need to assess the performance of the heating system.
But - how can I store the data over a longer period of time (such as a heating season) so that I can perform a truly meaningful analysis? My Home Assistant database is already about 80 MB in size, and my backup, which covers two weeks, is already taking up almost 1 GB of online storage. So I don't want to try to store the data for a heating period in the Home Assistant database. 
First, I had to make sure I knew what data I needed to retrieve from the database. To do this, I simply looked at the YAML code for the history graph card configuration shown above.
```YAML
title: History
type: history-graph
hours_to_show: 144
entities:
  - entity: sensor.ebusd_sc_ebusd_sc_act_supplytemp
  - entity: sensor.ebusd_hc1_ebusd_hc1_externaltemperature_externaltemperature
  - entity: sensor.ebusd_sc_ebusd_sc_act_operatingphase
  - entity: sensor.shellyplusht_c049ef88df9c_temperature
```
With the help of the “SQLite Web” Add-on, it is (fairly) easy to write a corresponding SQL that can be used to read the previous day's values from the database, eg.
```SQL
SELECT 'sensor.ebusd_sc_ebusd_sc_act_supplytemp', state, datetime(last_updated_ts,'unixepoch', 'localtime') FROM states WHERE metadata_id = (SELECT  metadata_id FROM states_meta WHERE entity_id = 'sensor.ebusd_sc_ebusd_sc_act_supplytemp') AND last_updated_ts > unixepoch(datetime('now', '-1 day'))
```
**Results (82)**
| 'sensor.ebusd_sc_ebusd_sc_act_supplytemp' | state | datetime(last_updated_ts,'unixepoch', 'localtime') |
|------------|:-----: |---------------|
|sensor.ebusd_sc_ebusd_sc_act_supplytemp| 	42.0| 	2025-09-04 14:37:41
|sensor.ebusd_sc_ebusd_sc_act_supplytemp| 	41.0| 	2025-09-04 14:46:41
|sensor.ebusd_sc_ebusd_sc_act_supplytemp| 	40.0| 	2025-09-04 15:38:16
|sensor.ebusd_sc_ebusd_sc_act_supplytemp| 	39.0| 	2025-09-04 15:41:16 
| ...                                   | ...    | ...



## Status
🚧 Early-stage developer utility – use at your own risk.  
Contributions and feedback are welcome!

## Acknowledgments
* used Noxon Commands from [clementleger](https://github.com/clementleger/noxonremote)
