FROM ubuntu:14.04
MAINTAINER Duane Johnson <duane.johnson@gmail.com>

# Add R to apt sources
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list

# Remove Python
RUN apt-get remove -y --force-yes `dpkg --list | grep python | grep "^ii" | awk '{print $2'}`

# Auto-remove packages
RUN apt-get autoremove -y --force-yes

# Install wget and build-essential
RUN apt-get update && apt-get install -y --force-yes \
  build-essential \
  git \
  libopenblas-dev \
  libopencv-dev \
  python-dev \
  python-numpy \
  python-setuptools \
  r-base \
  vim \
  libopencv-calib3d2.4:amd64 \
  libopencv-contrib2.4:amd64 \
  libopencv-core2.4:amd64 \
  libopencv-features2d2.4:amd64 \
  libopencv-flann2.4:amd64 \
  libopencv-highgui2.4:amd64 \
  libopencv-imgproc2.4:amd64 \
  libopencv-legacy2.4:amd64 \
  libopencv-ml2.4:amd64 \
  libopencv-objdetect2.4:amd64 \
  libopencv-video2.4:amd64 \
  wget

ADD downloads/cuda_7.5.18_linux.run /tmp/cuda.run

# Change to the /tmp directory
RUN cd /tmp && \
# Make the run file executable and extract
  chmod +x cuda.run && sync && \
  ./cuda.run -extract=`pwd` && \
# Install CUDA drivers (silent, no kernel)
  ./NVIDIA-Linux-x86_64-*.run -s --no-kernel-module && \
# Install toolkit (silent)  
  ./cuda-linux64-rel-*.run -noprompt && \
# Clean up
  rm -rf *

# Add to path
ENV PATH=/usr/local/cuda/bin:$PATH \
  LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Clone MXNet repo and move into it
RUN cd /root && git clone --recursive https://github.com/dmlc/mxnet && cd mxnet && \
# Copy config.mk
  cp make/config.mk config.mk && \
# Set OpenBLAS
  sed -i 's/USE_BLAS = atlas/USE_BLAS = openblas/g' config.mk && \
# Set CUDA flag
  sed -i 's/USE_CUDA = 0/USE_CUDA = 1/g' config.mk && \
  sed -i 's/USE_CUDA_PATH = NONE/USE_CUDA_PATH = \/usr\/local\/cuda/g' config.mk && \
# Set cuDNN flag
# TODO: Change when cuDNN v4 supported
  sed -i 's/USE_CUDNN = 0/USE_CUDNN = 0/g' config.mk && \
# Make 
  make -j"$(nproc)"

ADD downloads/Anaconda3-2.4.1-Linux-x86_64.sh /tmp/anaconda.sh

# Install Conda3
RUN cd /tmp && bash anaconda.sh -b -p /usr -f && \
  rm -f anaconda.sh

# Install various Python packages
RUN conda install -y joblib dill && \
  pip install pydicom

# Install MxNet
RUN cd /root/mxnet/python && python setup.py install

# Install OpenCV3
RUN conda install -y -c https://conda.binstar.org/menpo opencv3

# Set ~/mxnet as working directory
WORKDIR /root/mxnet

