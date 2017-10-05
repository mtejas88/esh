#!/bin/bash

echo "$(date)"
echo "Deleting from database..."
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/console.sh /opt/orientdb/orientdb-community-importers-2.2.27/bin/delete_commands.txt &&
echo "Creating Quick Vertices and Edges..." &&
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/Applicant.json &&
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/Recipient.json &&
echo "done"
wait
echo "Creating Edges..." &
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/CorrectFiber.json &
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/IncorrectFiber.json &
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/CorrectNonFiber.json &
sudo /opt/orientdb/orientdb-community-importers-2.2.27/bin/oetl.sh /home/sat/sat_r_programs/orientdb/etl/IncorrectNonFiber.json &
wait
echo "Done!"
