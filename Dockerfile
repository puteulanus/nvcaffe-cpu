FROM ubuntu:18.04 AS protobuf

RUN apt-get update && apt-get install -y libsystemd-dev patch wget unzip

# Protobuf3
RUN apt-get install -y --no-install-recommends autoconf automake libtool curl make g++ git \
        python-dev python-setuptools unzip && \
    git clone https://github.com/google/protobuf.git /usr/src/protobuf -b '3.2.x' && \
    cd /usr/src/protobuf && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local/protobuf && \
    make "-j$(nproc)" && \
    make install && \
    ldconfig && \
    cd python && \
    python setup.py install --cpp_implementation && \
    rm -rf /usr/src/protobuf

FROM ubuntu:18.04 AS caffe

COPY --from=protobuf /usr/local/protobuf /usr/local

# Caffe
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget curl
RUN wget -O cmake.sh https://github.com/Kitware/CMake/releases/download/v3.14.0-rc1/cmake-3.14.0-rc1-Linux-x86_64.sh && \
        bash cmake.sh --skip-license && rm -f cmake.sh
RUN apt-get install -y --no-install-recommends build-essential git gfortran libgflags-dev \
      libboost-filesystem-dev libboost-python-dev libboost-system-dev libboost-thread-dev libboost-regex-dev \
      libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libopencv-dev libsnappy-dev \
      python-all-dev python-dev python-h5py python-matplotlib python-numpy python-opencv python-pil \
      python-pip python-pydot python-scipy python-skimage python-sklearn libturbojpeg libturbojpeg-dev \
      doxygen libopenblas-dev && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py --force-reinstall && \
    rm -f get-pip.py && \
    git clone https://github.com/NVIDIA/caffe.git /usr/src/caffe -b 'caffe-0.15' && \
    pip install -r /usr/src/caffe/python/requirements.txt
RUN cd /usr/src/caffe && \
    mkdir build && \
    cd build && \
    cmake .. -DCPU_ONLY=1 -DBLAS=open -DCMAKE_INSTALL_PREFIX=/usr/local/caffe && \
    make -j"$(nproc)" && \
    make install

FROM ubuntu:18.04

ENV PYTHONPATH=/usr/local/python:$PYTHONPATH

COPY --from=protobuf /usr/local/protobuf /usr/local
COPY --from=caffe /usr/local/caffe /usr/local

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev python-dev \
        libboost-python-dev libboost-system-dev libboost-thread-dev \
        libgoogle-glog-dev libgflags-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev \
        libopencv-dev libopenblas-dev \
        python-opencv \
        ca-certificates \
        curl \
        python && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    pip install --upgrade --no-cache-dir pip && \
    rm -f get-pip.py

RUN pip install -U --no-cache-dir six matplotlib scipy networkx pillow
RUN pip install -U --no-cache-dir scikit-image==0.12.3 protobuf==3.2.0
