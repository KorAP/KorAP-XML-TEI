# Use alpine linux as base image
FROM alpine:latest AS tei2korapxml

RUN apk update && \
    apk add --no-cache git \
            perl \
            perl-io-socket-ssl \
            perl-dev \
            g++ \
            make \
            wget \
            perl-doc \
            libxml2-dev \
            perl-xml-libxml \
            perl-module-pluggable \
            openjdk21-jre \
            curl && \
    set -o pipefail

# Install cpm (faster CPAN module installer)
RUN curl -fsSL https://raw.githubusercontent.com/kupietz/cpm/main/cpm > /bin/cpm && chmod a+x /bin/cpm

# Copy repository respecting .dockerignore
COPY . /tei2korapxml

WORKDIR /tei2korapxml

# Install build-time dependencies required by Makefile.PL
RUN cpm install --test -g File::ShareDir::Install

# Install all Perl module dependencies from Makefile.PL
RUN cpm install --test -g \
    File::ShareDir \
    File::Share \
    XML::CompactTree::XS \
    XML::LibXML::Reader \
    IO::Compress::Zip \
    IO::Uncompress::Unzip \
    Log::Any \
    Time::Progress \
    XML::Loy

# Run Makefile.PL and install (this will install share files properly)
RUN perl Makefile.PL && make install

# Remove all build dependencies to reduce image size
RUN rm /bin/cpm && \
    apk del git \
            perl-dev \
            perl-doc \
            g++ \
            wget \
            libxml2-dev \
            curl && \
    rm -rf /root/.cpanm \
           /usr/local/share/man

# Create non-root user for security
RUN addgroup -S korap && \
    adduser -S tei2korapxml -G korap && \
    chown -R tei2korapxml:korap /tei2korapxml

USER tei2korapxml

# Set up entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command shows help
CMD ["--help"]

LABEL description="Docker Image for tei2korapxml - TEI P5 to KorAP-XML converter"
LABEL maintainer="korap@ids-mannheim.de"
LABEL repository="https://github.com/KorAP/KorAP-XML-TEI"

# Build command:
# docker build -f Dockerfile -t korap/tei2korapxml:x.xx-large .

# Slimming with mintoolkit/mint (https://github.com/mintoolkit/mint):
# mint build --http-probe=false \
#            --exec="tei2korapxml --version" \
#            --include-workdir=true \
#            --include-path="/usr/local/share/perl5/site_perl/KorAP/" \
#            --tag korap/tei2korapxml:x.xx \
#            --tag korap/tei2korapxml:latest \
#            korap/tei2korapxml:x.xx-large
