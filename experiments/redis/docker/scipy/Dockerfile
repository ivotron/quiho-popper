FROM jupyter/scipy-notebook

# install python dependencies
RUN conda install graphviz && \
    pip install graphviz && \
    conda install -n python2 graphviz && \
    bash -c 'source activate python2 && pip install graphviz'
