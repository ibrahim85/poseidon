FROM alpine:3.3
MAINTAINER Charlie Lewis <clewis@iqt.org>

RUN apk add --update \
    git \
    make \
    python \
    python-dev \
    py-pip \
    py-sphinx \
    tcpdump \
    && rm -rf /var/cache/apk/*

ADD . /poseidonWork
WORKDIR /poseidonWork
RUN pip install pip --upgrade

# install dependencies of plugins for poseidon
RUN for file in $(find poseidon/* -name "requirements.txt"); \
    do \
        pip install -r $file; \
    done

# install dependencies of plugins for tests
RUN for file in $(find plugins/* -name "requirements.txt"); \
    do \
        pip install -r $file; \
    done

# build documentation
RUN ln -s /poseidonWork/plugins /poseidonWork/poseidon/poseidonRest/plugins
RUN sphinx-apidoc -o docs poseidon -F --follow-links && cd docs && make html && make man

ENV PYTHONUNBUFFERED 0
EXPOSE 8000

ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:8000"]
CMD ["poseidon.poseidonRest.poseidonRest:api"]

# run linter
#RUN pylint --disable=all --enable=classes --disable=W poseidonRest

# run tests
RUN py.test -v --cov=poseidon/poseidonRest --cov=plugins --cov-report term-missing --cov-config .coveragerc