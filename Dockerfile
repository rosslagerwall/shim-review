FROM ctprdeuwrepoedge.jfrog.io/xs-local-docker-cloud/ddk:v1.8.4

WORKDIR /
COPY vendor.cer shimx64.efi *.patch /

#
# Fetch and verify source
#
RUN curl -LO https://github.com/rhboot/shim/releases/download/16.1/shim-16.1.tar.bz2
RUN echo '46319cd228d8f2c06c744241c0f342412329a7c630436fce7f82cf6936b1d603 shim-16.1.tar.bz2' | sha256sum -c
RUN tar -xvf shim-16.1.tar.bz2

#
# Patch source
#
WORKDIR /shim-16.1

# shim: Optionally tolerate MokManager being missing
# https://github.com/rhboot/shim/pull/759
RUN patch -p1 -F0 < /ignore-mm-missing.patch

# pe: Fix PF in GRUB after memattrs call
# https://github.com/rhboot/shim/pull/772
RUN patch -p1 -F0 < /0001-pe-Fix-PF-in-GRUB-after-memattrs-call.patch

# Add vendor SBAT entry
RUN echo 'shim.xs,1,Cloud Software Group,shim,16.1-4.xs9,mailto:security@xenserver.com' >> data/sbat.csv

#
# Build
#
ENV SOURCE_DATE_EPOCH=1759968000
RUN make POST_PROCESS_PE_FLAGS=-n VENDOR_CERT_FILE=/vendor.cer IGNORE_MM_MISSING=1

#
# Verify
#
RUN sha256sum /shimx64.efi shimx64.efi
RUN cmp -s /shimx64.efi shimx64.efi && echo OK || echo FAIL
