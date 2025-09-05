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
The yellow curve indicates the outside temperature, the orange one the inside temperature. The bar at the top shows the operating status of the heating system, which is mostly off now in summer. I hope this gives me everything I need to assess the performance of the heating system.\
But - how can I store the data over a longer period of time (such as a heating season) so that I can perform a truly meaningful analysis? My Home Assistant database is already about 80 MB in size, and my backup, which covers two weeks, is already taking up almost 1 GB of online storage. So I don't want to try to store the data for a heating period in the Home Assistant database. 
First, I have to make sure I know what data I need to retrieve from the database. To do this, I simply look at the YAML code for the history graph card configuration shown above.
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

This shows the temperature values of the heating flow. And it would look good in a CSV file, which I could then (somehow) process and analyze further. The SQL query retrieves the data from the previous day (``-1 day``) and should be run daily to ensure continuous recording.\
I can create the CSV file with a shell script that executes the necessary SQL queries. This is then called up daily by a Home Assistant automation. A script must be made known to Home Assistant by adding two entries (``allowlist_external_dirs:``, ``shell_command:``) in ``configuration.yaml`` like this
```YAML
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

homeassistant:
  allowlist_external_dirs:
    - "/config/userfiles"

shell_command:
  export_heizung_history: bash /config/userfiles/export_heizung_history.sh
...
```

I installed the Home Assistant Add-on “Studio Code Server” to conveniently edit the ``configuration.yaml`` file.
After adding the ``shell_command:`` to the configuration you need to restart Home Assistant ➞ Developer tools / Check and restart / RESTART / [Restart Home Assistant]. With the help of the integrated EXPLORER in Studio Code, I make the ``userfiles`` directory within the Home Assistant configuration **CONFIG** and create the script, see my [export_heizung_history.sh](https://github.com/ThomasHeinrichSchmidt/ha-history-exporter/blob/main/export_heizung_history.sh) as a sample.
![Studio Code Server](https://github.com/ThomasHeinrichSchmidt/ha-history-exporter/blob/main/media/StudioCodeServer.png?raw=true)
I haven't found a way to make the script executable using Studio Code, so I need to use the command line with the help of the “Terminal & SSH” Add-on.
```
[core-ssh ~]$ cd homeassistant
[core-ssh homeassistant]$ cd userfiles
[core-ssh userfiles]$ chmod +x export_heizung_history.sh 
```
I also create the desired CSV file with a suitable header in the ``userfiles`` directory, something like this  [heizung_history.csv](https://github.com/ThomasHeinrichSchmidt/ha-history-exporter/blob/main/heizung_history.csv).
The script appends its data to the bottom of the file every day, thus creating a continuous history.
And I achieve this with a Home Assistant automation that runs every night at 2 a.m. and calls the script.
![Home Assistant Export Automation](https://github.com/ThomasHeinrichSchmidt/ha-history-exporter/blob/main/media/ha-export-automation.png)
```YAML
   alias: Export Heizung History
   description: ""
   triggers:
     - trigger: time
       at: "02:00:00"
   conditions: []
   actions:
     - action: shell_command.export_heizung_history
       data: {}
   mode: single
```
As a test, I called up the script from the command line to see if the data arrived as desired. If everything looks good, you can empty the CSV file again except for the header and - collect the desired data every night from then on.

## Status
🚧 Early-stage developer utility – use at your own risk.  
Contributions and feedback are welcome!

## Acknowledgments
[Shell command w/sqlite3](https://community.home-assistant.io/t/shell-command-w-sqlite3/443430/3)\
[Shell Command](https://www.home-assistant.io/integrations/shell_command/)
