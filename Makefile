.PHONY: install

install:
	git clone https://github.com/manyids2/htmlgui.nvim.git $XDG_CONFIG_HOME/nvim-apps/htmlgui.nvim
	export NVIM_APPNAME=nvim-apps/htmlgui.nvim
	nvim

clean:
	echo "hello"
