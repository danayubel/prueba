# Usa la imagen oficial de Golang como base
FROM golang:1.21

# Establece el directorio de trabajo
WORKDIR /home/daniel/TFG/chaincode/energycontrol

# Copia los archivos go.mod y go.sum
COPY go.mod go.sum ./

# Descarga todas las dependencias. Las dependencias se almacenarán en caché si los archivos go.mod y go.sum no se cambian
RUN go mod download

# Copia el código fuente
COPY . .

# Compila el chaincode
RUN go build -o energycontrol

# Comando para ejecutar el chaincode
CMD ["./energycontrol"]
