FROM golang:1.17.8
WORKDIR /postgresbenchmark
COPY . /postgresbenchmark

# # Install dependencies
# RUN go mod vendor -v

# # Compile
# RUN go build -o main .

RUN git clone https://github.com/timescale/timescaledb.git
RUN cd timescaledb
# Find the latest release and checkout, e.g. for 2.5.0:
# RUN git checkout 2.5.1
# Bootstrap the build system
RUN ./bootstrap
# To build the extension
RUN cd build && make
# To install
RUN make install

# Run
# ENTRYPOINT "/postgresbenchmark/main"