echo "Building..."
cd src/ && 
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags "-w" *.go  && 
echo "Deploying..." &&
scp main intendance@ssh-intendance.alwaysdata.net:www/atable/server/main &&
echo "Cleaning up..." && 
rm main &&
echo "Done."