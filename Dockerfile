FROM osgeo/gdal:ubuntu-small-3.6.2

ENV PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    VENV_PATH=/opt/venv

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential python3-venv python3-dev git curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Non-root user
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USERNAME} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

# Python venv + Jupyter
RUN python3 -m venv $VENV_PATH \
 && $VENV_PATH/bin/pip install --upgrade pip setuptools wheel \
 && $VENV_PATH/bin/pip install jupyterlab==4.* notebook==7.* ipykernel==6.* pandas

# Ensure all shells use the venv by default
ENV PATH="/opt/venv/bin:$PATH"

# Install project deps
COPY requirements.txt /tmp/requirements.txt
RUN $VENV_PATH/bin/pip install --no-cache-dir -r /tmp/requirements.txt

# Global kernelspec pointing to venv Python
RUN $VENV_PATH/bin/pip install ipykernel==6.25.2
RUN $VENV_PATH/bin/python -m ipykernel install \
    --name earth-miner \
    --display-name "Earth Miner Env" \
    --prefix /usr/local

# Permissions and user
WORKDIR /app
COPY . /app
ENV PROJECT_ROOT=/app
#Paths for config, src and frontend imports. Add here any additional paths as needed.
ENV PYTHONPATH="/app:/app/src:/app/config:/app/frontend"

# Add .pth for system Python and for for virtualenv Python
RUN python -c "import site, pathlib; p = pathlib.Path(site.getsitepackages()[0], '_dev_paths.pth'); p.write_text('/app\n/app/src\n/app/config\n/app/frontend\n')"
RUN $VENV_PATH/bin/python -c "import site, pathlib; p = pathlib.Path(site.getsitepackages()[0], '_dev_paths.pth'); p.write_text('/app\n/app/src\n/app/config\n/app/frontend\n')"

# MLflow: write to /mlflow (host-mounted at runtime)
ENV MLFLOW_DIR=/mlflow
RUN mkdir -p ${MLFLOW_DIR} && chown -R ${USERNAME}:${USERNAME} ${MLFLOW_DIR}
ENV MLFLOW_TRACKING_URI="file:${MLFLOW_DIR}"
VOLUME ["/mlflow"]


RUN chown -R ${USERNAME}:${USERNAME} /app
USER ${USERNAME}
ENV HOME=/home/${USERNAME}

# (Optional but nice for interactive terminals)
RUN echo 'export PATH="/opt/venv/bin:$PATH"' >> /home/${USERNAME}/.bashrc

CMD ["sleep", "infinity"]
