# Stage 1 - copy package(s) and depends
# example: chrony
FROM scratch AS build_stage

# copy all files except ignored
COPY . ./

# Stage 2
FROM scratch
COPY --from=build_stage . ./
ENV LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/lib"
#EXPOSE 22
#USER 1000
ENTRYPOINT ["/bin/krb5kdc"]
