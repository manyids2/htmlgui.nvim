.PHONY: install

install:
	git clone https://github.com/manyids2/htmlgui.nvim.git ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	echo "\n    = 🔥\nRun with\n  bash: export NVIM_APPNAME=nvim-apps/htmlgui.nvim nvim\n  fish: set -x NVIM_APPNAME=nvim-apps/htmlgui.nvim; nvim"

run:
	echo "\n    = 🔥\nRun with\n  bash: export NVIM_APPNAME=nvim-apps/htmlgui.nvim nvim\n  fish: set -x NVIM_APPNAME=nvim-apps/htmlgui.nvim; nvim"

clean:
	echo "Deleting " ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	echo "Deleting " ${XDG_DATA_HOME}/nvim-apps/htmlgui.nvim
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	rm -rf ${XDG_DATA_HOME}/nvim-apps/htmlgui.nvim
