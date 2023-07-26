# This script is a workaround for a bug related to user defined functions
# It imports an SQL dump in two steps : functions and schema then data
# The first argument is the name of the file dump
#
# The typical commands to run previoulsy are 
# pg_dump -U <user> -h <host> -d intendance_prod > intendance.dump
# scp <user>@<host>:intendance.dump intendance.dump

echo "Spliting schema and data..." && 
line=$(grep -n "COPY" $1 | cut -d: -f1 | head -1) &&  
line="$((line-1))" && 
(head -$line > schema.sql; cat > data.sql) < $1 && 
echo "Resetting DB..." && 
dropdb --if-exists --force intendance_prod && createdb intendance_prod && 
echo "Importing..." && 
psql intendance_prod < schema.sql && 
psql intendance_prod < data.sql && 
echo "Cleaning up" && 
rm schema.sql data.sql