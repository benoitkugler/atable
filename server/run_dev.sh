# equivalent for go run src/main.go

export $(cat .env | xargs) &&

cd src && 
go build *.go && 
mv main .. && 
cd .. && 
./main -dev
