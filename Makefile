.PHONY: install

define ANNOUNCE_INSTALL

	   = 🔥

  Setup first time with

  bash: export NVIM_APPNAME=nvim-apps/htmlgui.nvim; nvim
  fish: set -x NVIM_APPNAME nvim-apps/htmlgui.nvim; nvim

endef
export ANNOUNCE_INSTALL

define ANNOUNCE_DELETE

	  Delete?

	🔴 ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	🔴 ${XDG_DATA_HOME}/nvim-apps/htmlgui.nvim

endef
export ANNOUNCE_DELETE

define ANNOUNCE_RUN

     = 🔥

  Set NVIM_APPNAME ( currently:  ${NVIM_APPNAME} )

  bash: export NVIM_APPNAME=nvim-apps/htmlgui.nvim
  fish: set -x NVIM_APPNAME nvim-apps/htmlgui.nvim

  Go to examples folder, open index.html file

  cd ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/examples; nvim index.html

endef
export ANNOUNCE_RUN

install:
	git clone ./.git ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/lua/htmlgui
	@echo "$$ANNOUNCE_INSTALL"

dev:
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	cp -r ./ ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/lua/htmlgui
	@echo "$$ANNOUNCE_INSTALL"

run:
	@echo "$$ANNOUNCE_RUN"

clean:
	@echo "$$ANNOUNCE_DELETE"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	rm -rf ${XDG_DATA_HOME}/nvim-apps/htmlgui.nvim
