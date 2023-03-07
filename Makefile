ifneq ($(strip $(spec)),)
	spec_file = $(spec)_spec.lua
endif

test:
	nvim --headless \
		-u "tests/init.lua" \
		-c "PlenaryBustedDirectory tests/spec/$(spec_file) { minimal_init = 'tests/init.lua', sequential = true }"

clean:
	rm -rf .tests

local-ci:
	act \
		--container-architecture linux/amd64 \
		--secret GITHUB_TOKEN \
		--job "$(job)" \
		--rm
