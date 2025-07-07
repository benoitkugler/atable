# Build script to execute from www/
# static files are pulled from git; go executable should be
# uploaded after cross compilation
#
git pull && 
echo "Removing unused files" && 
# only keep server/static
rm -rf atable/.git atable/atable-web atable/atable-mobile atable/server/src atable/server/migrations &&
echo "Done (pending uploading executable to atable/server)."
