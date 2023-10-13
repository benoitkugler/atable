echo "Building..."
cd src/ && 
go build -ldflags "-w" *.go  && 
echo "Deploying..." &&
scp main intendance@ssh-intendance.alwaysdata.net:www/main &&
echo "Cleaning up..." && 
rm main &&
echo "Done."