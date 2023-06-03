.PHONY: install

define ANNOUNCE_INSTALL

	   = 🔥

  Install to /usr/bin/htmlgui.nvim ?

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

  Using NVIM_APPNAME:  ${NVIM_APPNAME}

  Go to examples folder, open index.html file

  cd examples;
	htmlgui.nvim index.html

endef
export ANNOUNCE_RUN

define ANNOUNCE_DEV

     = 🔥

	Set Debug/Release in lua/bootstrap/plugins.lua

endef
export ANNOUNCE_DEV


install:
	export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
	cp -r ./ ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/lua/htmlgui
	cd ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	chmod +x htmlgui.nvim
	@echo "$$ANNOUNCE_INSTALL"
	sudo cp htmlgui.nvim /usr/bin/htmlgui.nvim

dev:
	export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	cp -r ./ ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/
	rm -r ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim/lua/htmlgui
	@echo "$$ANNOUNCE_INSTALL"

run:
	export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
	@echo "$$ANNOUNCE_RUN"

clean:
	export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
	@echo "$$ANNOUNCE_DELETE"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf ${XDG_CONFIG_HOME}/nvim-apps/htmlgui.nvim
	rm -rf ${XDG_DATA_HOME}/nvim-apps/htmlgui.nvim
