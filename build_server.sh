# Build script to execute from atable
# static files are pulled from git; go executable should be
# uploaded after cross compilation
#
git pull && 
echo "Removing unused files" && 
# only keep server/static
rm -rf atable-web atable-mobile server/src server/migrations &&
echo "Done (pending uploading executable to atable/server)."
