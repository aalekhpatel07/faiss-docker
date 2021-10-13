FROM centos:8 AS build

WORKDIR /app

# CentOS bug: we have to `yum update` or the packaged cmake won't run
RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled powertools && \
    yum update -y && \
    yum install -y make cmake gcc-c++ clang-libs unzip

# Get Faiss v1.7.1 from source.
RUN curl https://codeload.github.com/facebookresearch/faiss/zip/refs/tags/v1.7.1 -o /usr/local/faiss-1.7.1.tar.gz
RUN unzip /usr/local/faiss-1.7.1.tar.gz
RUN mv faiss-1.7.1 /usr/local/
RUN rm /usr/local/faiss-1.7.1.tar.gz

RUN yum install -y \
	python3 \
	python3-devel \
	python3-numpy \
	openblas-devel \
	swig \
	openblas-static \
	lapack-static \
 	gcc-toolset-10-gcc-gfortran \
	libomp-devel

# Build FAISS.
RUN cd /usr/local/faiss-1.7.1/ && \
    cmake \
    	-DCMAKE_INSTALL_PREFIX=/usr \
        -DFAISS_ENABLE_GPU=OFF \
	-DFAISS_ENABLE_C_API=ON \
	-DFAISS_ENABLE_PYTHON=OFF \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-B .

# Build and install FAISS.
RUN cd /usr/local/faiss-1.7.1 && \
	make -j8 faiss && \
	make install

# Copy the new shared library to LD_LIBRARY_PATH.
RUN cp /usr/local/faiss-1.7.1/c_api/libfaiss_c.so /usr/lib64/
RUN cp /usr/local/faiss-1.7.1/faiss/libfaiss.so /usr/lib64/
ENV LD_LIBRARY_PATH="/usr/lib64/:/usr/lib/:$LD_LIBRARY_PATH"

# This is the recommended way to install Faiss for use from Python.
# Get miniconda.
RUN curl https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh -o /usr/local/get_miniconda.sh
RUN sh /usr/local/get_miniconda.sh -b
ENV PATH="/root/miniconda3/bin:$PATH"
RUN rm /usr/local/get_miniconda.sh

# Install faiss-cpu (Python wrapper) from pytorch channel.
RUN conda install -c pytorch faiss-cpu

CMD ["/bin/bash"]
