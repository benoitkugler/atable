echo "Grouping SQL statements in create_all_gen.sql..." &&
echo "" > create_all_gen.sql && 
#
echo "-- sql/users/gen_create.sql" >> create_all_gen.sql &&
cat ../src/sql/users/gen_create.sql >> create_all_gen.sql 
#
echo "-- sql/menus/gen_create.sql" >> create_all_gen.sql &&
cat ../src/sql/menus/gen_create.sql >> create_all_gen.sql 
#
echo "-- sql/sejours/gen_create.sql" >> create_all_gen.sql &&
cat ../src/sql/sejours/gen_create.sql >> create_all_gen.sql 
# 
echo "-- sql/orders/gen_create.sql" >> create_all_gen.sql &&
cat ../src/sql/orders/gen_create.sql >> create_all_gen.sql 
# 
echo "Splitting tables, constraints and json functions..."
cd sql_statements && 
go run sql.go &&
echo "Done."
 