FROM docker.io/andimajore/biocyper_base:python3.10 as setup-stage

# default for BIOCYPHER_CONFIG if non other is set
ARG BIOCYPHER_CONFIG=config/biocypher_docker_config.yaml
ENV env_biocypher_config=$BIOCYPHER_CONFIG

WORKDIR /usr/app/
COPY pyproject.toml ./
RUN poetry config virtualenvs.create false && poetry install
COPY . ./
RUN mv ${BIOCYPHER_CONFIG} config/biocypher_config.yaml
RUN python3 create_knowledge_graph.py

FROM docker.io/neo4j:4.4-enterprise as deploy-stage
COPY --from=setup-stage /usr/app/biocypher-out/ /var/lib/neo4j/import/
COPY docker/* ./
RUN cat biocypher_entrypoint_patch.sh | cat - /startup/docker-entrypoint.sh > docker-entrypoint.sh && mv docker-entrypoint.sh /startup/ && chmod +x /startup/docker-entrypoint.sh