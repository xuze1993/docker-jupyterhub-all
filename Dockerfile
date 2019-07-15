FROM jupyter/all-spark-notebook


USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends octave \
        octave-symbolic octave-miscellaneous \
        python-sympy \
        gnuplot ghostscript && \
    apt-get install -yq --no-install-recommends git g++ debhelper devscripts gnupg wget curl && \
    apt-get install -y software-properties-common  && \
    apt-add-repository ppa:ansible/ansible  && \
    apt-get update && \
    apt-get install -y ansible   && \
    apt-get install -y  ant-optional default-jre  default-jdk jython    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    


RUN mkdir /cling
RUN chown -R $NB_USER:users /cling
WORKDIR /cling

USER $NB_UID

RUN conda install --quiet --yes \
    'octave_kernel' && \
    conda clean -tipsy && \
fix-permissions $CONDA_DIR


COPY  kernel.json    /home/jovyan/jupyter-kernel-jsr223/kernelspec/kernel.json
COPY download_cling.py download_cling.py
RUN python download_cling.py

WORKDIR /cling/share/cling/Jupyter/kernel
RUN pip install -e .
RUN jupyter-kernelspec install --user cling-cpp11


RUN  pip install ansible-kernel  jupyterlab  jupyterlab_sql==0.2.1  jupyterlab_latex  && \
     python -m ansible_kernel.install

RUN git clone https://github.com/fiber-space/jupyter-kernel-jsr223.git  && \
    cd jupyter-kernel-jsr223    && \
    ant

RUN   jupyter kernelspec install  /home/jovyan/jupyter-kernel-jsr223/kernelspec --user jovyan

RUN mkdir -p $HOME/$NB_UID
WORKDIR $HOME/$NB_UID

RUN  jupyter serverextension enable jupyterlab_sql --py --sys-prefix  && \
     jupyter lab build

RUN  jupyter serverextension enable --sys-prefix jupyterlab_latex   && \
         jupyter labextension install @jupyterlab/latex

EXPOSE 8888
ENTRYPOINT ["tini", "-g", "--"]
CMD jupyter-lab  --port=8888
