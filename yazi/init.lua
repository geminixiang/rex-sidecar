pcall(function()
	require("git"):setup { order = 1500 }
end)

local opener = os.getenv("REX_SIDECAR_BIN")
local last = nil

ps.sub("hover", function()
	local h = cx.active.current.hovered
	if not opener or not h or h.cha.is_dir then
		return
	end
	local path = tostring(h.url)
	if path == last then
		return
	end
	last = path
	ya.emit("shell", { ya.quote(opener) .. " --preview " .. ya.quote(path), orphan = true })
end)

function Entity:click(event, up)
	if up or not (event.is_left or event.is_right) then
		return
	end
	ya.emit("reveal", { self._file.url })
	if self._file.cha.is_dir then
		ya.emit("enter", {})
	elseif event.is_right then
		ya.emit("open", {})
	end
end

function Header:cwd()
	local max = self._area.w - self._right_width
	if max <= 0 then
		return ""
	end
	local s = "‹ " .. ya.readable_path(tostring(self._current.cwd))
	return ui.Span(ui.truncate(s, { max = max, rtl = true })):style(th.mgr.cwd)
end

function Header:click(event, up)
	if up or not event.is_left then
		return
	end
	ya.emit("leave", {})
end
