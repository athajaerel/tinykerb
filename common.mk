.PHONY: tinykerb
tinykerb: BUILD_FLAGS := \
		--http-proxy=false \
		--no-cache=false \
		--compress=true \
		--layers=true \
		--format=oci \
		--build-arg=REALM=K3S.LAB \
		--build-arg=PW_MASTER=wibble \
		--build-arg=USER_ADMIN=god \
		--build-arg=PW_ADMIN=wibble \
		--build-arg=PKGS="${pkgs} ${temp_pkgs}" \
		--build-arg=STAGE_PKGS="${pkgs}" \
		--log-level=info

tinykerb:
	@# templatisation here?
	@#ln -sf bash bin/sh
	cat Containerfile.common Containerfile.kdc >Containerfile
	podman build $(BUILD_FLAGS) \
		-f=Containerfile \
		--tag=$(id_kdc) \
		.
	cat Containerfile.common Containerfile.kadmind >Containerfile
	podman build $(BUILD_FLAGS) \
		-f=Containerfile \
		--tag=$(id_kadmind) \
		.
	rm Containerfile

.PHONY: debug
debug: BUILD_FLAGS := \
		--http-proxy=false \
		--no-cache=false \
		--compress=true \
		--layers=true \
		--format=oci \
		--build-arg=REALM=K3S.LAB \
		--build-arg=PW_MASTER=wibble \
		--build-arg=USER_ADMIN=god \
		--build-arg=PW_ADMIN=wibble \
		--build-arg=PKGS="${pkgs} ${temp_pkgs}" \
		--build-arg=STAGE_PKGS="${pkgs} ${temp_pkgs}" \
		--log-level=debug

debug:
	@# templatisation here?
	@#ln -sf bash bin/sh
	cat Containerfile.common Containerfile.kdc >Containerfile
	podman build $(BUILD_FLAGS) \
		-f=Containerfile \
		--tag=$(id_kdc_debug) \
		.
	cat Containerfile.common Containerfile.kadmind >Containerfile
	podman build $(BUILD_FLAGS) \
		-f=Containerfile \
		--tag=$(id_kadmind_debug) \
		.
	rm Containerfile

.PHONY: guts
guts:
	@mkdir -p guts
	@rm -f kdc.tar
	@podman save $(id_kdc) -o kdc.tar
	@tar xpf kdc.tar -C guts/

.PHONY: clean-guts
clean-guts:
	@rm -rf guts

.PHONY: clean
clean: clean-guts prune

.PHONY: prune
prune:
	podman rmi -a || true

.PHONY: stats
stats: clean-guts guts
	@echo Size of tinykerb-kdc in bytes:
	@podman image inspect tinykerb-kdc | jq ".[0].Size"
	@echo Number of layers:
	@podman image inspect tinykerb-kdc | jq ".[0].RootFS.Layers | length"
	@echo Number of files:
	@tar tf guts/*tar | wc -l
