setup:
	git submodule update --init --recursive

update-theme:
	git submodule update --remote --merge

dev:
	hugo serve -D