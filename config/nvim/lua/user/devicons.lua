local status_ok, dev_icons = pcall(require, "nvim-web-devicons")
if not status_ok then
	print("Unable to load plugin : dev_icons")
	return
end

dev_icons.setup {

}

