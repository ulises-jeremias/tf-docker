ARG UBUNTU_VERSION=18.04

ARG ARCH=
ARG CUDA=10.0

FROM nvidia/cuda${ARCH:+-$ARCH}:${CUDA}-base-ubuntu${UBUNTU_VERSION} as base
# UBUNTU_VERSION, ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)

ARG UBUNTU_VERSION
ARG ARCH
ARG CUDA
ARG CUDNN=7.4.1.5-1

# Needed for string substitution 
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies
RUN apt-get update -q && apt-get install -y --no-install-recommends \
    build-essential \
    cuda-command-line-tools-${CUDA/./-} \
    cuda-cublas-${CUDA/./-} \
    cuda-cufft-${CUDA/./-} \
    cuda-curand-${CUDA/./-} \
    cuda-cusolver-${CUDA/./-} \
    cuda-cusparse-${CUDA/./-} \
    curl \
    libcudnn7=${CUDNN}+cuda${CUDA} \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libzmq3-dev \
    pkg-config \
    software-properties-common \
    unzip

ARG UBUNTU_VERSION_X=18
ARG UBUNTU_VERSION_Y=04

RUN apt-get update -q && \
    apt-get install nvinfer-runtime-trt-repo-ubuntu${UBUNTU_VERSION_X}${UBUNTU_VERSION_Y}-5.0.2-ga-cuda${CUDA} \
    && apt-get update -q \
    && apt-get install -y --no-install-recommends libnvinfer5=5.0.2-1+cuda${CUDA} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

ARG USE_PYTHON_3_NOT_2=ON
ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
ARG PYTHON=python${_PY_SUFFIX}
ARG PIP=pip${_PY_SUFFIX}

ENV LANG C.UTF-8

COPY starterfile.py /tf/starterfile.py

RUN apt-get update -q
RUN apt-get install -y ${PYTHON} ${PYTHON}-pip git
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ${PIP} --no-cache-dir install --upgrade \
    pip \
    setuptools

# Some TF tools expect a "python" binary
RUN ln -s $(which ${PYTHON}) /usr/local/bin/python 

# Options:
#   tensorflow
#   tensorflow-gpu
#   tf-nightly
#   tf-nightly-gpu
# Set --build-arg TF_PACKAGE_VERSION=1.11.0rc0 to install a specific version.
# Installs the latest version by default.
ARG TF_PACKAGE=tensorflow
ARG TF_PACKAGE_VERSION=2.0.0-alpha0
RUN ${PIP} install ${TF_PACKAGE}${TF_PACKAGE_VERSION:+==${TF_PACKAGE_VERSION}}

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

RUN ${PIP} install jupyter matplotlib
RUN ${PIP} install jupyter_http_over_ws
RUN jupyter serverextension enable --py jupyter_http_over_ws

RUN mkdir /.local && chmod a+rwx /.local

RUN ${PYTHON} --version

WORKDIR /tf
EXPOSE 8888

RUN ${PYTHON} -m ipykernel.kernelspec

CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]
