# Build script to execute from www/
# static files are pulled from git; go executable should be
# uploaded after cross compilation
#
echo "Removing current folder"
rm -rf atable/ &&
git clone https://github.com/benoitkugler/atable.git && 
echo "Removing unused files" && 
cd atable && 
# only keep server/static
rm -rf .git atable-web atable-mobile server/src server/migrations &&
echo "Done (pending uploading executable to atable/server)."
