ARG UBUNTU_VERSION=latest

FROM ubuntu:${UBUNTU_VERSION} as base

RUN apt-get update -q && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libcurl3-dev \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libzmq3-dev \
    pkg-config \
    rsync \
    software-properties-common \
	sudo \
    unzip \
    zip \
    zlib1g-dev \
    openjdk-8-jdk \
    openjdk-8-jre-headless \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG USE_PYTHON_3_NOT_2=ON
ARG _PY_SUFFIX=${USE_PYTHON_3_NOT_2:+3}
ARG PYTHON=python${_PY_SUFFIX}
ARG PIP=pip${_PY_SUFFIX}

ENV LANG C.UTF-8

COPY starterfile.py /tf/starterfile.py

RUN apt-get update -q
RUN apt-get install -y ${PYTHON} ${PYTHON}-pip
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

RUN apt-get update -q && apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    openjdk-8-jdk \
    ${PYTHON}-dev \
    virtualenv \
    swig

RUN ${PIP} --no-cache-dir install \
    Pillow \
    h5py \
    keras_applications \
    keras_preprocessing \
    matplotlib \
    mock \
    numpy \
    scipy \
    sklearn \
    pandas \
    portpicker \
    && test "${USE_PYTHON_3_NOT_2}" -eq 1 && true || ${PIP} --no-cache-dir install \
    enum34

# Install bazel
ARG BAZEL_VERSION=0.24.1
RUN mkdir /bazel && \
    wget -O /bazel/installer.sh "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    wget -O /bazel/LICENSE.txt "https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE" && \
    chmod +x /bazel/installer.sh && \
    /bazel/installer.sh && \
    rm -f /bazel/installer.sh

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc

RUN ${PIP} install jupyter matplotlib
RUN ${PIP} install jupyter_http_over_ws
RUN jupyter serverextension enable --py jupyter_http_over_ws

RUN mkdir -p /tf/tensorflow-tutorials && chmod -R a+rwx /tf/
RUN mkdir /.local && chmod a+rwx /.local
RUN apt-get install -y --no-install-recommends wget
WORKDIR /tf/tensorflow-tutorials
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/basic_classification.ipynb
RUN wget https://raw.githubusercontent.com/tensorflow/docs/master/site/en/tutorials/keras/basic_text_classification.ipynb
RUN apt-get autoremove -y && apt-get remove -y wget

RUN ${PYTHON} --version

WORKDIR /tf
EXPOSE 8888

RUN ${PYTHON} -m ipykernel.kernelspec

CMD ["bash", "-c", "source /etc/bash.bashrc && jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]
